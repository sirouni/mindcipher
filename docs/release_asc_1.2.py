#!/usr/bin/env python3
"""App Store Connect 1.2 (dossier redesign).

Steps are idempotent and can be run separately:

    python3 docs/release_asc_1.2.py version      # create 1.2 (copies 1.1 localizations), copyright/release type
    python3 docs/release_asc_1.2.py metadata     # description / promo / what's new from docs/asc_1.2.json
    python3 docs/release_asc_1.2.py aso          # subtitle / keywords / description opener from docs/aso_1.2.json
    python3 docs/release_asc_1.2.py screenshots  # replace IPHONE_65 sets with assets/asc-dossier/<locale>/
    python3 docs/release_asc_1.2.py build        # attach newest processed build 5, encryption exempt
    python3 docs/release_asc_1.2.py status
    python3 docs/release_asc_1.2.py submit       # explicit — sends for review

`prepare` = version + metadata + aso + screenshots + build.
"""

from __future__ import annotations

import hashlib
import json
import sys
import time
from pathlib import Path

import jwt
import requests

ROOT = Path(__file__).resolve().parents[1]
COPY = json.loads((ROOT / "docs/asc_1.2.json").read_text())
SHOTS = ROOT / "assets/asc-dossier"
SHOT_ORDER = [
    "01_case.png", "02_report.png", "03_lie.png", "04_cabinet.png",
    "05_night.png", "06_shapes.png", "07_daily.png", "08_home.png",
]
ISS = "6fba9ede-5341-4112-a55f-d00d4e7cb05b"
KID = "Y8W69V3U7C"
KEY = Path("/Users/wangxiao/.appstoreconnect/private_keys/AuthKey_Y8W69V3U7C.p8").read_text()
APP_ID = "6777428188"
BASE = "https://api.appstoreconnect.apple.com"
VERSION = "1.2"
BUILD_NUMBER = "6"
DISPLAY_TYPE = "APP_IPHONE_65"
LOCALES = ["en-US", "zh-Hans", "zh-Hant", "ja", "ko", "es-ES", "ar-SA", "de-DE", "fr-FR", "he", "pt-BR", "tr"]


def log(*a):
    print(*a, flush=True)


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISS, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        KEY,
        algorithm="ES256",
        headers={"alg": "ES256", "kid": KID, "typ": "JWT"},
    )


def api(method: str, path: str, ok=(200, 201, 204), **kwargs):
    url = path if path.startswith("http") else BASE + path
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    for attempt in range(5):
        r = requests.request(method, url, headers=headers, timeout=90, **kwargs)
        if r.status_code in (429, 500, 502, 503) and attempt < 4:
            time.sleep(2 ** attempt)
            continue
        if r.status_code not in ok and r.status_code >= 400:
            log(f"API {method} {path} -> {r.status_code}\n{r.text[:1600]}")
            r.raise_for_status()
        return r.json() if r.text else {}
    r.raise_for_status()
    return {}


# --------------------------------------------------------------------------- version

def find_version() -> dict | None:
    data = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions", params={"filter[versionString]": VERSION, "limit": 5}).get("data", [])
    return data[0] if data else None


def ensure_version() -> str:
    v = find_version()
    if v:
        log("version exists", v["id"], v["attributes"]["appStoreState"])
        vid = v["id"]
    else:
        created = api(
            "POST",
            "/v1/appStoreVersions",
            json={
                "data": {
                    "type": "appStoreVersions",
                    "attributes": {"platform": "IOS", "versionString": VERSION, "releaseType": "AFTER_APPROVAL"},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                }
            },
        )
        vid = created["data"]["id"]
        log("version created", vid)
    api(
        "PATCH",
        f"/v1/appStoreVersions/{vid}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": vid,
                "attributes": {"copyright": "© 2026 Xiao Wang", "releaseType": "AFTER_APPROVAL"},
            }
        },
    )
    return vid


def localizations(vid: str) -> dict[str, dict]:
    return {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations", params={"limit": 50}).get("data", [])
    }


def ensure_localizations(vid: str) -> dict[str, dict]:
    locs = localizations(vid)
    for locale in LOCALES:
        if locale in locs:
            continue
        created = api(
            "POST",
            "/v1/appStoreVersionLocalizations",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": locale},
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}},
                }
            },
        )
        locs[locale] = created["data"]
        log("localization created", locale)
    return locs


# --------------------------------------------------------------------------- metadata

def patch_metadata(vid: str):
    locs = ensure_localizations(vid)
    for locale in LOCALES:
        copy = COPY[locale]
        loc = locs[locale]
        attrs = {
            "description": copy["description"],
            "promotionalText": copy["promotionalText"],
            "whatsNew": copy["whatsNew"],
            "supportUrl": "https://sirouni.github.io/mindcipher/support.html",
            "marketingUrl": "https://sirouni.github.io/mindcipher/",
        }
        if not loc["attributes"].get("keywords"):
            # New localizations do not inherit keywords; pull them from the live version.
            live = live_keywords().get(locale)
            if live:
                attrs["keywords"] = live
        api(
            "PATCH",
            f"/v1/appStoreVersionLocalizations/{loc['id']}",
            json={"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}},
        )
        log("metadata", locale)


_LIVE_KW: dict[str, str] | None = None


def live_keywords() -> dict[str, str]:
    global _LIVE_KW
    if _LIVE_KW is None:
        live = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions", params={"filter[appStoreState]": "READY_FOR_SALE", "limit": 2}).get("data", [])
        _LIVE_KW = {}
        if live:
            for loc in localizations(live[0]["id"]).values():
                _LIVE_KW[loc["attributes"]["locale"]] = loc["attributes"].get("keywords") or ""
    return _LIVE_KW


# --------------------------------------------------------------------------- ASO (subtitle / keywords / opener)

def editable_app_info() -> str:
    infos = api("GET", f"/v1/apps/{APP_ID}/appInfos").get("data", [])
    for i in infos:
        if i["attributes"]["appStoreState"] not in {"READY_FOR_SALE", "REPLACED_WITH_NEW_INFO", "REMOVED_FROM_SALE"}:
            return i["id"]
    raise RuntimeError("no editable appInfo (all READY_FOR_SALE) — create the version first")


def apply_aso(vid: str):
    aso = json.loads((ROOT / "docs/aso_1.2.json").read_text())
    info_id = editable_app_info()
    infos = {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations", params={"limit": 50}).get("data", [])
    }
    locs = ensure_localizations(vid)
    for locale in LOCALES:
        a = aso[locale]
        assert len(a["subtitle"]) <= 30 and len(a["keywords"]) <= 100, locale
        if locale in infos:
            api(
                "PATCH",
                f"/v1/appInfoLocalizations/{infos[locale]['id']}",
                json={
                    "data": {
                        "type": "appInfoLocalizations",
                        "id": infos[locale]["id"],
                        "attributes": {"name": "Mind Cipher", "subtitle": a["subtitle"]},
                    }
                },
            )
        else:
            api(
                "POST",
                "/v1/appInfoLocalizations",
                json={
                    "data": {
                        "type": "appInfoLocalizations",
                        "attributes": {"locale": locale, "name": "Mind Cipher", "subtitle": a["subtitle"]},
                        "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}},
                    }
                },
            )
        desc = COPY[locale]["description"].split("\n\n", 1)
        desc = a["desc_open"] + ("\n\n" + desc[1] if len(desc) > 1 else "")
        api(
            "PATCH",
            f"/v1/appStoreVersionLocalizations/{locs[locale]['id']}",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": locs[locale]["id"],
                    "attributes": {"keywords": a["keywords"], "description": desc},
                }
            },
        )
        log("aso", locale, "|", a["subtitle"], "|", len(a["keywords"]))


# --------------------------------------------------------------------------- screenshots

def screenshot_set(loc_id: str) -> str:
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets").get("data", [])
    for s in sets:
        if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE:
            return s["id"]
    created = api(
        "POST",
        "/v1/appScreenshotSets",
        json={
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                "relationships": {
                    "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}
                },
            }
        },
    )
    return created["data"]["id"]


def upload_shot(set_id: str, path: Path):
    data = path.read_bytes()
    reserved = api(
        "POST",
        "/v1/appScreenshots",
        json={
            "data": {
                "type": "appScreenshots",
                "attributes": {"fileName": path.name, "fileSize": len(data)},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
            }
        },
    )
    sid = reserved["data"]["id"]
    for op in reserved["data"]["attributes"].get("uploadOperations") or []:
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
        start = op.get("offset") or 0
        length = op.get("length") or len(data)
        put = requests.request(op["method"], op["url"], headers=hdrs, data=data[start : start + length], timeout=180)
        if put.status_code >= 400:
            raise RuntimeError(f"upload {path.name} {put.status_code} {put.text[:300]}")
    api(
        "PATCH",
        f"/v1/appScreenshots/{sid}",
        json={
            "data": {
                "type": "appScreenshots",
                "id": sid,
                "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
            }
        },
    )
    log("  uploaded", path.name)


def replace_screenshots(vid: str, only: list[str] | None = None):
    locs = ensure_localizations(vid)
    for locale in only or LOCALES:
        files = [SHOTS / locale / n for n in SHOT_ORDER]
        missing = [f for f in files if not f.exists()]
        if missing:
            log("skip", locale, "missing", [m.name for m in missing])
            continue
        set_id = screenshot_set(locs[locale]["id"])
        existing = api("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", [])
        names = [s["attributes"].get("fileName") for s in existing]
        sizes = [s["attributes"].get("fileSize") for s in existing]
        if names == SHOT_ORDER and sizes == [f.stat().st_size for f in files]:
            log(locale, "already up to date")
            continue
        for sh in existing:
            api("DELETE", f"/v1/appScreenshots/{sh['id']}", ok=(200, 204))
        log(locale, "cleared", len(existing))
        for f in files:
            upload_shot(set_id, f)
        # Remove any other iPhone display sizes so ASC does not show the 1.1 shots alongside.
        for s in api("GET", f"/v1/appStoreVersionLocalizations/{locs[locale]['id']}/appScreenshotSets").get("data", []):
            if s["attributes"]["screenshotDisplayType"] != DISPLAY_TYPE and s["attributes"]["screenshotDisplayType"].startswith("APP_IPHONE"):
                api("DELETE", f"/v1/appScreenshotSets/{s['id']}", ok=(200, 204))
                log(locale, "removed set", s["attributes"]["screenshotDisplayType"])


# --------------------------------------------------------------------------- build

def newest_build() -> dict | None:
    builds = api(
        "GET",
        "/v1/builds",
        params={
            "filter[app]": APP_ID,
            "filter[preReleaseVersion.version]": VERSION,
            "filter[version]": BUILD_NUMBER,
            "sort": "-uploadedDate",
            "limit": 5,
        },
    ).get("data", [])
    return builds[0] if builds else None


def attach_build(vid: str, wait_minutes: int = 40):
    end = time.time() + wait_minutes * 60
    build = None
    while time.time() < end:
        build = newest_build()
        state = build["attributes"]["processingState"] if build else "MISSING"
        log("build", build["id"] if build else "-", state)
        if build and state == "VALID":
            break
        if build and state in {"FAILED", "INVALID"}:
            raise RuntimeError(f"build {state}")
        time.sleep(45)
    if not build or build["attributes"]["processingState"] != "VALID":
        raise RuntimeError("build not processed yet")
    bid = build["id"]
    try:
        api(
            "PATCH",
            f"/v1/builds/{bid}",
            json={"data": {"type": "builds", "id": bid, "attributes": {"usesNonExemptEncryption": False}}},
        )
        log("build encryption: exempt")
    except requests.HTTPError:
        log("build encryption patch skipped")
    api(
        "PATCH",
        f"/v1/appStoreVersions/{vid}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": vid,
                "relationships": {"build": {"data": {"type": "builds", "id": bid}}},
            }
        },
    )
    log("build attached", bid)


# --------------------------------------------------------------------------- status / submit

def status(vid: str):
    v = api("GET", f"/v1/appStoreVersions/{vid}", params={"include": "build"})
    a = v["data"]["attributes"]
    log("version", VERSION, a["appStoreState"], "copyright:", a.get("copyright"), "release:", a.get("releaseType"))
    inc = v.get("included") or []
    for b in inc:
        if b["type"] == "builds":
            log("build", b["attributes"]["version"], b["attributes"]["processingState"])
    if not inc:
        log("build: none attached")
    for locale, loc in sorted(localizations(vid).items()):
        sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets").get("data", [])
        counts = []
        for s in sets:
            n = len(api("GET", f"/v1/appScreenshotSets/{s['id']}/appScreenshots").get("data", []))
            counts.append(f"{s['attributes']['screenshotDisplayType']}={n}")
        wn = (loc["attributes"].get("whatsNew") or "")[:40].replace("\n", " ")
        log(f"  {locale:8} kw={'y' if loc['attributes'].get('keywords') else 'n'} whatsNew='{wn}…' shots: {', '.join(counts) or 'none'}")


def submit(vid: str):
    # appStoreVersionSubmissions no longer allows CREATE; use the Review Submissions API.
    existing = api(
        "GET",
        "/v1/reviewSubmissions",
        params={"filter[app]": APP_ID, "filter[state]": "READY_FOR_REVIEW,UNRESOLVED_ISSUES", "limit": 5},
    ).get("data", [])
    if existing:
        rs_id = existing[0]["id"]
        log("reusing review submission", rs_id, existing[0]["attributes"]["state"])
    else:
        rs = api(
            "POST",
            "/v1/reviewSubmissions",
            json={
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                }
            },
        )
        rs_id = rs["data"]["id"]
        log("review submission", rs_id)
    items = api("GET", f"/v1/reviewSubmissions/{rs_id}/items").get("data", [])
    if not items:
        api(
            "POST",
            "/v1/reviewSubmissionItems",
            json={
                "data": {
                    "type": "reviewSubmissionItems",
                    "relationships": {
                        "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": rs_id}},
                        "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}},
                    },
                }
            },
        )
        log("added 1.2 to review submission")
    done = api(
        "PATCH",
        f"/v1/reviewSubmissions/{rs_id}",
        json={"data": {"type": "reviewSubmissions", "id": rs_id, "attributes": {"submitted": True}}},
    )
    log("SUBMITTED", rs_id, done["data"]["attributes"]["state"])
    status(vid)


def main():
    step = sys.argv[1] if len(sys.argv) > 1 else "status"
    vid = ensure_version() if step in {"version", "prepare"} else (find_version() or {}).get("id")
    if not vid:
        raise SystemExit("1.2 does not exist yet — run `version` first")
    if step in {"metadata", "prepare"}:
        patch_metadata(vid)
    if step in {"aso", "prepare"}:
        apply_aso(vid)
    if step in {"screenshots", "prepare"}:
        replace_screenshots(vid, sys.argv[2:] or None)
    if step in {"build", "prepare"}:
        attach_build(vid)
    if step == "submit":
        submit(vid)
    else:
        status(vid)


if __name__ == "__main__":
    main()
