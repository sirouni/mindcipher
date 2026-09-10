#!/usr/bin/env python3
"""Apply full ASO: withdraw 1.1, patch metadata, upload EN preview, resubmit."""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path

import jwt
import requests

ROOT = Path("/Users/wangxiao/Projects/CodeBreaker")
ASO = json.loads((ROOT / "docs/aso_1.1.json").read_text())
PREVIEW = ROOT / "assets/app_preview.mp4"
ISS = "6fba9ede-5341-4112-a55f-d00d4e7cb05b"
KID = "Y8W69V3U7C"
KEY = Path("/Users/wangxiao/.appstoreconnect/private_keys/AuthKey_Y8W69V3U7C.p8").read_text()
APP_ID = "6777428188"
VID = "244a4372-2a06-4079-81c6-45def7c5b553"
SID = "4253f31f-1466-45d8-b3c2-7e5f9ffa4a66"
BASE = "https://api.appstoreconnect.apple.com"


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
            log(f"API {method} {path} -> {r.status_code}\n{r.text[:1600]}")
            r.raise_for_status()
        return r.json() if r.text else {}
    r.raise_for_status()
    return {}


def first_paragraph_replaced(text: str, opener: str) -> str:
    parts = text.split("\n\n", 1)
    if len(parts) == 1:
        return opener
    return opener + "\n\n" + parts[1]


def cancel_review():
    v = api("GET", f"/v1/appStoreVersions/{VID}")
    state = v["data"]["attributes"]["appStoreState"]
    log("version state", state)
    if state in {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"}:
        return
    subs = api("GET", f"/v1/apps/{APP_ID}/reviewSubmissions", params={"filter[platform]": "IOS"})
    open_ids = []
    for s in subs.get("data", []):
        st = s["attributes"].get("state")
        log("submission", s["id"], st)
        if st in {"WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW"}:
            open_ids.append(s["id"])
    if SID not in open_ids:
        open_ids.append(SID)
    for sid in open_ids:
        try:
            api(
                "PATCH",
                f"/v1/reviewSubmissions/{sid}",
                json={
                    "data": {
                        "type": "reviewSubmissions",
                        "id": sid,
                        "attributes": {"canceled": True},
                    }
                },
            )
            log("canceled", sid)
        except requests.HTTPError:
            log("cancel failed", sid)
    for _ in range(30):
        state = api("GET", f"/v1/appStoreVersions/{VID}")["data"]["attributes"]["appStoreState"]
        log("wait state", state)
        if state in {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"}:
            return
        time.sleep(8)
    raise RuntimeError(f"version still {state}")


def patch_metadata():
    locs = {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations").get("data", [])
    }
    info_id = "85195a21-c079-4457-829f-f1ae0a56a61d"
    infos = {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations").get("data", [])
    }
    for locale, copy in ASO.items():
        if not isinstance(copy, dict) or "subtitle" not in copy:
            continue
        if locale in infos:
            api(
                "PATCH",
                f"/v1/appInfoLocalizations/{infos[locale]['id']}",
                json={
                    "data": {
                        "type": "appInfoLocalizations",
                        "id": infos[locale]["id"],
                        "attributes": {"name": "Mind Cipher", "subtitle": copy["subtitle"]},
                    }
                },
            )
            log("info subtitle", locale, copy["subtitle"])
        loc = locs[locale]
        desc = first_paragraph_replaced(loc["attributes"].get("description") or "", copy["desc_open"])
        api(
            "PATCH",
            f"/v1/appStoreVersionLocalizations/{loc['id']}",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc["id"],
                    "attributes": {
                        "keywords": copy["keywords"],
                        "promotionalText": copy["promo"],
                        "description": desc,
                    },
                }
            },
        )
        log("version aso", locale, len(copy["keywords"]))
    return {locale: loc["id"] for locale, loc in locs.items()}


def upload_preview(en_loc_id: str):
    if not PREVIEW.is_file():
        log("no preview file")
        return
    sets = api("GET", f"/v1/appStoreVersionLocalizations/{en_loc_id}/appPreviewSets").get("data", [])
    set_id = None
    for s in sets:
        if s["attributes"].get("previewType") == "IPHONE_65":
            set_id = s["id"]
            break
    if not set_id:
        created = api(
            "POST",
            "/v1/appPreviewSets",
            json={
                "data": {
                    "type": "appPreviewSets",
                    "attributes": {"previewType": "IPHONE_65"},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": en_loc_id}
                        }
                    },
                }
            },
        )
        set_id = created["data"]["id"]
        log("preview set", set_id)
    existing = api("GET", f"/v1/appPreviewSets/{set_id}/appPreviews").get("data", [])
    for p in existing:
        api("DELETE", f"/v1/appPreviews/{p['id']}", ok=(200, 204))
        log("deleted old preview", p["id"])
    data = PREVIEW.read_bytes()
    reserved = api(
        "POST",
        "/v1/appPreviews",
        json={
            "data": {
                "type": "appPreviews",
                "attributes": {"fileName": PREVIEW.name, "fileSize": len(data)},
                "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": set_id}}},
            }
        },
    )
    pid = reserved["data"]["id"]
    for op in reserved["data"]["attributes"].get("uploadOperations") or []:
        hdrs = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
        start = op.get("offset") or 0
        length = op.get("length") or len(data)
        put = requests.request(op["method"], op["url"], headers=hdrs, data=data[start : start + length], timeout=180)
        if put.status_code >= 400:
            raise RuntimeError(f"preview upload {put.status_code} {put.text[:300]}")
    api(
        "PATCH",
        f"/v1/appPreviews/{pid}",
        json={
            "data": {
                "type": "appPreviews",
                "id": pid,
                "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()},
            }
        },
    )
    log("preview uploaded", pid)
    for i in range(20):
        info = api("GET", f"/v1/appPreviews/{pid}")
        st = (info["data"]["attributes"].get("assetDeliveryState") or {}).get("state")
        log("preview state", st)
        if st in {"COMPLETE", "FAILED"}:
            return st
        time.sleep(6)
    return "PROCESSING"


def resubmit():
    created = api(
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
    sid = created["data"]["id"]
    log("new submission", sid, created["data"]["attributes"])
    api(
        "POST",
        "/v1/reviewSubmissionItems",
        json={
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sid}},
                    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VID}},
                },
            }
        },
    )
    final = api(
        "PATCH",
        f"/v1/reviewSubmissions/{sid}",
        json={"data": {"type": "reviewSubmissions", "id": sid, "attributes": {"submitted": True}}},
    )
    log("RESUBMITTED", final["data"]["attributes"])
    v = api("GET", f"/v1/appStoreVersions/{VID}")
    log("version", v["data"]["attributes"]["appStoreState"])


def main():
    for loc, copy in ASO.items():
        if not isinstance(copy, dict) or "subtitle" not in copy:
            continue
        assert len(copy["subtitle"]) <= 30, loc
        assert len(copy["keywords"]) <= 100, loc
        assert len(copy["promo"]) <= 170, loc
    cancel_review()
    loc_ids = patch_metadata()
    upload_preview(loc_ids["en-US"])
    resubmit()


if __name__ == "__main__":
    main()
