#!/usr/bin/env python3
"""Finish ASC 1.1: remaining screenshots, attach build, submit for review."""

from __future__ import annotations

import hashlib
import time
from pathlib import Path

import jwt
import requests

ROOT = Path("/Users/wangxiao/Projects/CodeBreaker")
SHOTS = ROOT / "assets/asc"
ISS = "6fba9ede-5341-4112-a55f-d00d4e7cb05b"
KID = "Y8W69V3U7C"
KEY = Path("/Users/wangxiao/.appstoreconnect/private_keys/AuthKey_Y8W69V3U7C.p8").read_text()
APP_ID = "6777428188"
VID = "244a4372-2a06-4079-81c6-45def7c5b553"
BUILD_ID = "cae17058-ff2e-498b-bfa4-cddeccb9cbfa"
BASE = "https://api.appstoreconnect.apple.com"
SHOT_ORDER = [
    "01_gameplay.png",
    "02_lie.png",
    "03_notes.png",
    "04_duel.png",
    "05_campaign.png",
    "06_challenge.png",
    "07_daily.png",
    "08_achievements.png",
]


def log(*args):
    print(*args, flush=True)


def token() -> str:
    now = int(time.time())
    return jwt.encode(
        {"iss": ISS, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        KEY,
        algorithm="ES256",
        headers={"alg": "ES256", "kid": KID, "typ": "JWT"},
    )


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api(method: str, path: str, ok=(200, 201, 204), **kwargs):
    url = path if path.startswith("http") else BASE + path
    for attempt in range(5):
        r = requests.request(method, url, headers=headers(), timeout=90, **kwargs)
        if r.status_code in (429, 500, 502, 503) and attempt < 4:
            time.sleep(2 ** attempt)
            continue
        if r.status_code not in ok and r.status_code >= 400:
            log(f"API {method} {path} -> {r.status_code}\n{r.text[:1500]}")
            r.raise_for_status()
        return r.json() if r.text else {}
    r.raise_for_status()
    return {}


def screenshot_set(loc_id: str) -> str:
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets").get("data", [])
    for s in sets:
        if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_65":
            return s["id"]
    created = api(
        "POST",
        "/v1/appScreenshotSets",
        json={
            "data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": "APP_IPHONE_65"},
                "relationships": {
                    "appStoreVersionLocalization": {
                        "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                    }
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
        chunk = data[start : start + length]
        put = requests.request(op["method"], op["url"], headers=hdrs, data=chunk, timeout=180)
        if put.status_code >= 400:
            raise RuntimeError(f"upload {path.name} {put.status_code} {put.text[:300]}")
    api(
        "PATCH",
        f"/v1/appScreenshots/{sid}",
        json={
            "data": {
                "type": "appScreenshots",
                "id": sid,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": hashlib.md5(data).hexdigest(),
                },
            }
        },
    )
    log("  uploaded", path.name)


def ensure_tr_shots():
    locs = {
        loc["attributes"]["locale"]: loc["id"]
        for loc in api("GET", f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations").get("data", [])
    }
    lid = locs["tr"]
    set_id = screenshot_set(lid)
    existing = api("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", [])
    log("tr existing", len(existing))
    if len(existing) >= 8:
        log("tr shots already present")
        return
    for sh in existing:
        api("DELETE", f"/v1/appScreenshots/{sh['id']}", ok=(200, 204))
        log("  deleted", sh["attributes"].get("fileName"))
    for name in SHOT_ORDER:
        upload_shot(set_id, SHOTS / "tr" / name)
    log("tr shots done")


def patch_copyright():
    api(
        "PATCH",
        f"/v1/appStoreVersions/{VID}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": VID,
                "attributes": {"copyright": "© 2026 Xiao Wang", "releaseType": "AFTER_APPROVAL"},
            }
        },
    )
    log("copyright patched")


def attach_build():
    api(
        "PATCH",
        f"/v1/appStoreVersions/{VID}",
        json={
            "data": {
                "type": "appStoreVersions",
                "id": VID,
                "relationships": {"build": {"data": {"type": "builds", "id": BUILD_ID}}},
            }
        },
    )
    log("build attached", BUILD_ID)


def encryption():
    b = api("GET", f"/v1/builds/{BUILD_ID}")
    log("build attrs", {k: b["data"]["attributes"].get(k) for k in (
        "processingState", "usesNonExemptEncryption", "expired", "minOsVersion", "version"
    )})
    try:
        api(
            "PATCH",
            f"/v1/builds/{BUILD_ID}",
            json={
                "data": {
                    "type": "builds",
                    "id": BUILD_ID,
                    "attributes": {"usesNonExemptEncryption": False},
                }
            },
        )
        log("build encryption patched")
    except requests.HTTPError as e:
        log("build encryption patch failed", e)

    try:
        decls = api("GET", "/v1/appEncryptionDeclarations", params={"filter[app]": APP_ID, "limit": 20})
    except requests.HTTPError:
        log("list encryption decls skipped")
        return
    log("existing decls", [
        (d["id"], d["attributes"].get("appEncryptionDeclarationState"), d["attributes"].get("usesEncryption"),
         d["attributes"].get("exempt"))
        for d in decls.get("data", [])
    ])
    approved = None
    for d in decls.get("data", []):
        st = d["attributes"].get("appEncryptionDeclarationState")
        if st in {"APPROVED", "ACTIVE"} or d["attributes"].get("exempt") or d["attributes"].get("usesEncryption") is False:
            approved = d
            break
    if not approved:
        payloads = [
            {
                "usesEncryption": False,
                "exempt": True,
                "containsProprietaryCryptography": False,
                "containsThirdPartyCryptography": False,
                "availableOnFrenchStore": True,
            },
            {
                "usesEncryption": False,
            },
        ]
        for attrs in payloads:
            try:
                created = api(
                    "POST",
                    "/v1/appEncryptionDeclarations",
                    json={
                        "data": {
                            "type": "appEncryptionDeclarations",
                            "attributes": attrs,
                            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
                        }
                    },
                )
                approved = created["data"]
                log("created encryption decl", approved["id"], attrs)
                break
            except requests.HTTPError:
                continue
    if approved:
        try:
            api(
                "PATCH",
                f"/v1/builds/{BUILD_ID}/relationships/appEncryptionDeclaration",
                json={"data": {"type": "appEncryptionDeclarations", "id": approved["id"]}},
            )
            log("linked encryption decl", approved["id"])
        except requests.HTTPError as e:
            log("link encryption failed", e)


def submit():
    created = api(
        "POST",
        "/v1/appStoreVersionSubmissions",
        json={
            "data": {
                "type": "appStoreVersionSubmissions",
                "relationships": {
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VID}}
                },
            }
        },
    )
    log("SUBMITTED", created.get("data", {}).get("id"), created.get("data", {}).get("attributes"))
    v = api("GET", f"/v1/appStoreVersions/{VID}")
    log("version state", v["data"]["attributes"].get("appStoreState"), v["data"]["attributes"].get("appVersionState"))


def main():
    ensure_tr_shots()
    patch_copyright()
    encryption()
    attach_build()
    submit()


if __name__ == "__main__":
    main()
