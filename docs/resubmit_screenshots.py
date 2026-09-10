#!/usr/bin/env python3
"""Withdraw 1.1, replace IPHONE_65 screenshots, resubmit."""

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
SID = "2853ec55-612e-4817-a8b4-dc53f9ed40aa"
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


def log(*a):
    print(*a, flush=True)


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISS, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        KEY,
        algorithm="ES256",
        headers={"alg": "ES256", "kid": KID, "typ": "JWT"},
    )


def headers():
    return {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}


def api(method, path, ok=(200, 201, 204), **kwargs):
    url = path if path.startswith("http") else BASE + path
    for attempt in range(5):
        r = requests.request(method, url, headers=headers(), timeout=90, **kwargs)
        if r.status_code in (429, 500, 502, 503) and attempt < 4:
            time.sleep(2 ** attempt)
            continue
        if r.status_code not in ok and r.status_code >= 400:
            log(f"API {method} {path} -> {r.status_code}\n{r.text[:1400]}")
            r.raise_for_status()
        return r.json() if r.text else {}
    r.raise_for_status()
    return {}


def cancel():
    state = api("GET", f"/v1/appStoreVersions/{VID}")["data"]["attributes"]["appStoreState"]
    log("version", state)
    if state in {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"}:
        return
    subs = api("GET", f"/v1/apps/{APP_ID}/reviewSubmissions", params={"filter[platform]": "IOS"})
    ids = [SID]
    for s in subs.get("data", []):
        st = s["attributes"].get("state")
        log("submission", s["id"], st)
        if st in {"WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW"}:
            ids.append(s["id"])
    for sid in dict.fromkeys(ids):
        try:
            api(
                "PATCH",
                f"/v1/reviewSubmissions/{sid}",
                json={"data": {"type": "reviewSubmissions", "id": sid, "attributes": {"canceled": True}}},
            )
            log("canceled", sid)
        except requests.HTTPError:
            log("cancel failed", sid)
    for _ in range(24):
        state = api("GET", f"/v1/appStoreVersions/{VID}")["data"]["attributes"]["appStoreState"]
        log("wait", state)
        if state in {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"}:
            return
        time.sleep(6)
    raise RuntimeError(state)


def screenshot_set(loc_id):
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


def upload_shot(set_id, path: Path):
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
            raise RuntimeError(f"{path.name} {put.status_code} {put.text[:200]}")
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


def upload_all():
    locs = {
        loc["attributes"]["locale"]: loc["id"]
        for loc in api("GET", f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations").get("data", [])
    }
    for locale, lid in locs.items():
        folder = SHOTS / locale
        set_id = screenshot_set(lid)
        existing = []
        url = f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200"
        while url:
            page = api("GET", url)
            existing.extend(page.get("data", []))
            url = page.get("links", {}).get("next")
        for sh in existing:
            api("DELETE", f"/v1/appScreenshots/{sh['id']}", ok=(200, 204))
        leftover = api("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=200").get("data", [])
        for sh in leftover:
            api("DELETE", f"/v1/appScreenshots/{sh['id']}", ok=(200, 204))
        log("cleared", locale, len(existing), "+", len(leftover))
        for name in SHOT_ORDER:
            p = folder / name
            if p.exists():
                upload_shot(set_id, p)
        log("shots done", locale)


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
    log("submission", sid)
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
    cancel()
    upload_all()
    resubmit()


if __name__ == "__main__":
    main()
