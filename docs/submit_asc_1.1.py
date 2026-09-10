#!/usr/bin/env python3
"""Create App Store Connect 1.1, push metadata, upload 6.5\" screenshots."""

from __future__ import annotations

import hashlib
import json
import re
import time
from pathlib import Path

import jwt
import requests

ROOT = Path("/Users/wangxiao/Projects/CodeBreaker")
SHOTS = ROOT / "assets/asc"
MD = (ROOT / "docs/ASC_1.1.md").read_text()
ISS = "6fba9ede-5341-4112-a55f-d00d4e7cb05b"
KID = "Y8W69V3U7C"
KEY = Path("/Users/wangxiao/.appstoreconnect/private_keys/AuthKey_Y8W69V3U7C.p8").read_text()
APP_ID = "6777428188"
BASE = "https://api.appstoreconnect.apple.com"
PRIVACY = "https://sirouni.github.io/mindcipher/privacy.html"
SUPPORT = "https://sirouni.github.io/mindcipher/support.html"
MARKETING = "https://sirouni.github.io/mindcipher/"
REVIEW = """Mind Cipher is a single-player and pass-and-play Mastermind-style puzzle.

How to demo:
1. Open the app. Skip or finish the short tutorial.
2. Play Daily Challenge or Classic Missions, Level 1. Fill slots from the color picker and tap Submit.
3. To see Lie Mode, open Lie Missions and play Level 1. Exactly one feedback row in the round is fake. The winning guess is always honest.

In-app purchases:
- com.codebreaker.app.pro — one-time unlock. Free content is Daily, Duel, Classic 1–40, Lie 1–80.
- Hint coin packs are optional consumables. Coins can also be earned by playing. Not required to finish free levels.

Other:
- No account. No ads. Game Center is optional (leaderboard com.codebreaker.app.total).
- Language can be changed in Settings → Game → Language.
- Restore Purchases is in the store / paywall.
"""

IAP = {
    "6777923527": {  # pro
        "en-US": ("Pro Unlock", "Rest of Lie & Classic, Free Play, editor"),
        "zh-Hans": ("解锁 Pro", "解锁剩余关卡、自由模式和编辑器"),
        "zh-Hant": ("解鎖 Pro", "解鎖剩餘關卡、自由模式和編輯器"),
        "ja": ("Proを解除", "残りの任務、フリープレイ、編集"),
        "ko": ("Pro 해제", "나머지 캠페인, 자유 플레이, 편집기"),
        "es-ES": ("Desbloquear Pro", "Restos de campañas, libre y editor"),
        "ar-SA": ("فتح Pro", "باقي الحملتين واللعب الحر والمحرر"),
        "de-DE": ("Pro freischalten", "Rest der Kampagnen, frei, Editor"),
        "fr-FR": ("Débloquer Pro", "Reste des campagnes, libre, éditeur"),
        "he": ("פתח Pro", "שאר העלילות, חופשי והעורך"),
        "pt-BR": ("Desbloquear Pro", "Resto das campanhas, livre, editor"),
        "tr": ("Pro’yu aç", "Kampanya gerisi, serbest oyun, editör"),
    },
    "6777938793": {
        "en-US": ("5 Hint Coins", "A small pack of hints"),
        "zh-Hans": ("5 枚提示币", "一小包提示"),
        "zh-Hant": ("5 枚提示幣", "一小包提示"),
        "ja": ("ヒントコイン 5", "少量のヒント"),
        "ko": ("힌트 코인 5", "작은 힌트 팩"),
        "es-ES": ("5 monedas de pista", "Un pack pequeño de pistas"),
        "ar-SA": ("5 عملات تلميح", "حزمة تلميحات صغيرة"),
        "de-DE": ("5 Tipp-Münzen", "Ein kleines Tipp-Paket"),
        "fr-FR": ("5 pièces d’indice", "Un petit pack d’indices"),
        "he": ("5 מטבעות רמז", "חבילת רמזים קטנה"),
        "pt-BR": ("5 moedas de dica", "Um pacote pequeno de dicas"),
        "tr": ("5 ipucu jetonu", "Küçük bir ipucu paketi"),
    },
    "6777939640": {
        "en-US": ("15 Hint Coins", "Best value for casual play"),
        "zh-Hans": ("15 枚提示币", "日常游玩更划算"),
        "zh-Hant": ("15 枚提示幣", "日常遊玩更划算"),
        "ja": ("ヒントコイン 15", "普段使いにちょうどいい"),
        "ko": ("힌트 코인 15", "가볍게 쓰기 좋은 구성"),
        "es-ES": ("15 monedas de pista", "Mejor valor para jugar"),
        "ar-SA": ("15 عملة تلميح", "أفضل قيمة للعب العادي"),
        "de-DE": ("15 Tipp-Münzen", "Gutes Preis-Leistungs-Paket"),
        "fr-FR": ("15 pièces d’indice", "Meilleur rapport pour jouer"),
        "he": ("15 מטבעות רמז", "הכי משתלם למשחק רגוע"),
        "pt-BR": ("15 moedas de dica", "Melhor custo para jogar"),
        "tr": ("15 ipucu jetonu", "Gündelik oyun için iyi değer"),
    },
    "6777941000": {
        "en-US": ("50 Hint Coins", "A large pack of hints"),
        "zh-Hans": ("50 枚提示币", "一大包提示"),
        "zh-Hant": ("50 枚提示幣", "一大包提示"),
        "ja": ("ヒントコイン 50", "多めのヒント"),
        "ko": ("힌트 코인 50", "큰 힌트 팩"),
        "es-ES": ("50 monedas de pista", "Un pack grande de pistas"),
        "ar-SA": ("50 عملة تلميح", "حزمة تلميحات كبيرة"),
        "de-DE": ("50 Tipp-Münzen", "Ein großes Tipp-Paket"),
        "fr-FR": ("50 pièces d’indice", "Un grand pack d’indices"),
        "he": ("50 מטבעות רמז", "חבילת רמזים גדולה"),
        "pt-BR": ("50 moedas de dica", "Um pacote grande de dicas"),
        "tr": ("50 ipucu jetonu", "Büyük bir ipucu paketi"),
    },
}

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


def api(method: str, path: str, **kwargs):
    url = path if path.startswith("http") else BASE + path
    for attempt in range(5):
        r = requests.request(method, url, headers=headers(), timeout=60, **kwargs)
        if r.status_code in (429, 500, 502, 503) and attempt < 4:
            time.sleep(2 ** attempt)
            continue
        if r.status_code >= 400:
            print(f"API {method} {path} -> {r.status_code}\n{r.text[:1200]}")
            r.raise_for_status()
        return r.json() if r.text else {}
    r.raise_for_status()
    return {}


def parse_locales() -> dict[str, dict]:
    blocks = re.split(r"\n## ", MD)
    out = {}
    for b in blocks:
        m = re.search(r"`([a-z]{2}(?:-[A-Za-z]{2,4})?)`", b[:80])
        if not m:
            continue
        loc = m.group(1)
        if loc not in {
            "en-US", "zh-Hans", "zh-Hant", "ja", "ko", "es-ES",
            "ar-SA", "de-DE", "fr-FR", "he", "pt-BR", "tr",
        }:
            continue

        def field(label):
            mm = re.search(rf"\*\*{label}:\*\* (.+)", b)
            return mm.group(1).strip() if mm else ""

        def fenced(label):
            mm = re.search(rf"\*\*{label}:\*\*\n```\n(.+?)\n```", b, re.S)
            return mm.group(1).strip() if mm else ""

        out[loc] = {
            "name": field("Name") or "Mind Cipher",
            "subtitle": field("Subtitle"),
            "keywords": field("Keywords"),
            "promo": fenced("Promotional Text"),
            "description": fenced("Description"),
            "whatsNew": fenced("What’s New") or fenced("What's New"),
        }
    return out


def get_or_create_version() -> str:
    data = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions", params={"filter[platform]": "IOS", "limit": 10})
    for v in data.get("data", []):
        if v["attributes"]["versionString"] == "1.1":
            print("version 1.1 exists", v["id"], v["attributes"]["appStoreState"])
            return v["id"]
    created = api(
        "POST",
        "/v1/appStoreVersions",
        json={
            "data": {
                "type": "appStoreVersions",
                "attributes": {
                    "platform": "IOS",
                    "versionString": "1.1",
                    "copyright": "© 2026 Xiao Wang",
                    "releaseType": "AFTER_APPROVAL",
                },
                "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
            }
        },
    )
    vid = created["data"]["id"]
    print("created version 1.1", vid)
    time.sleep(2)
    return vid


def editable_app_info() -> str:
    data = api("GET", f"/v1/apps/{APP_ID}/appInfos")
    for info in data.get("data", []):
        state = info["attributes"].get("state") or info["attributes"].get("appStoreState")
        if state in {"PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "DEVELOPER_REJECTED"}:
            return info["id"]
        if "PREPARE" in str(state) or "REVIEW" in str(state):
            return info["id"]
    # newest non-sale
    for info in data.get("data", []):
        if info["attributes"].get("appStoreState") != "READY_FOR_SALE":
            return info["id"]
    raise RuntimeError(f"no editable appInfo: {data}")


def upsert_info_locs(info_id: str, locales: dict):
    existing = {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations").get("data", [])
    }
    for locale, copy in locales.items():
        attrs = {
            "name": "Mind Cipher",
            "subtitle": copy["subtitle"],
            "privacyPolicyUrl": PRIVACY,
        }
        if locale in existing:
            api(
                "PATCH",
                f"/v1/appInfoLocalizations/{existing[locale]['id']}",
                json={"data": {"type": "appInfoLocalizations", "id": existing[locale]["id"], "attributes": attrs}},
            )
            print("info patched", locale)
        else:
            api(
                "POST",
                "/v1/appInfoLocalizations",
                json={
                    "data": {
                        "type": "appInfoLocalizations",
                        "attributes": {"locale": locale, **attrs},
                        "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}},
                    }
                },
            )
            print("info created", locale)


def upsert_version_locs(vid: str, locales: dict) -> dict[str, str]:
    existing = {
        loc["attributes"]["locale"]: loc
        for loc in api("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations").get("data", [])
    }
    ids = {}
    for locale, copy in locales.items():
        attrs = {
            "description": copy["description"],
            "keywords": copy["keywords"],
            "marketingUrl": MARKETING,
            "promotionalText": copy["promo"],
            "supportUrl": SUPPORT,
            "whatsNew": copy["whatsNew"],
        }
        if locale in existing:
            lid = existing[locale]["id"]
            api(
                "PATCH",
                f"/v1/appStoreVersionLocalizations/{lid}",
                json={"data": {"type": "appStoreVersionLocalizations", "id": lid, "attributes": attrs}},
            )
            print("version patched", locale)
        else:
            created = api(
                "POST",
                "/v1/appStoreVersionLocalizations",
                json={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "attributes": {"locale": locale, **attrs},
                        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}},
                    }
                },
            )
            lid = created["data"]["id"]
            print("version created", locale)
        ids[locale] = lid
    return ids


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


def clear_set(set_id: str):
    shots = api("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots").get("data", [])
    for sh in shots:
        api("DELETE", f"/v1/appScreenshots/{sh['id']}")
        print("  deleted", sh["attributes"].get("fileName"))


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
        put = requests.request(op["method"], op["url"], headers=hdrs, data=chunk, timeout=120)
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
    print("  uploaded", path.name)


def upload_screens(loc_ids: dict[str, str]):
    for locale, lid in loc_ids.items():
        folder = SHOTS / locale
        if not folder.is_dir():
            print("skip shots, missing folder", locale)
            continue
        set_id = screenshot_set(lid)
        clear_set(set_id)
        for name in SHOT_ORDER:
            p = folder / name
            if p.exists():
                upload_shot(set_id, p)
        print("shots done", locale)


def upsert_review(vid: str):
    existing = api("GET", f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")
    attrs = {
        "contactFirstName": "Jason",
        "contactLastName": "Wang",
        "contactPhone": "+8618612697029",
        "contactEmail": "sirouni@msn.com",
        "demoAccountRequired": False,
        "notes": REVIEW,
    }
    if existing.get("data"):
        rid = existing["data"]["id"]
        api(
            "PATCH",
            f"/v1/appStoreReviewDetails/{rid}",
            json={"data": {"type": "appStoreReviewDetails", "id": rid, "attributes": attrs}},
        )
        print("review patched")
    else:
        api(
            "POST",
            "/v1/appStoreReviewDetails",
            json={
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": attrs,
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}},
                }
            },
        )
        print("review created")


def upsert_iap(locales: dict):
    for iap_id, by_loc in IAP.items():
        existing = {
            loc["attributes"]["locale"]: loc
            for loc in api("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations").get("data", [])
        }
        for locale in locales:
            name, desc = by_loc[locale]
            if len(desc) > 45:
                raise SystemExit(f"IAP desc too long {locale} {iap_id}: {len(desc)}")
            if locale in existing:
                state = existing[locale]["attributes"].get("state")
                if state in {"APPROVED", "ACTIVE"}:
                    print("iap skip", iap_id, locale, state)
                    continue
                lid = existing[locale]["id"]
                api(
                    "PATCH",
                    f"/v1/inAppPurchaseLocalizations/{lid}",
                    json={
                        "data": {
                            "type": "inAppPurchaseLocalizations",
                            "id": lid,
                            "attributes": {"name": name, "description": desc},
                        }
                    },
                )
            else:
                api(
                    "POST",
                    "/v1/inAppPurchaseLocalizations",
                    json={
                        "data": {
                            "type": "inAppPurchaseLocalizations",
                            "attributes": {"locale": locale, "name": name, "description": desc},
                            "relationships": {
                                "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}
                            },
                        }
                    },
                )
            print("iap", iap_id, locale)


def main():
    locales = parse_locales()
    print("parsed", list(locales))
    for loc, c in locales.items():
        assert c["description"] and c["whatsNew"] and c["keywords"] and c["subtitle"], loc
        assert len(c["subtitle"]) <= 30, (loc, len(c["subtitle"]))
        assert len(c["keywords"]) <= 100, (loc, len(c["keywords"]))
    vid = get_or_create_version()
    info_id = editable_app_info()
    print("appInfo", info_id)
    upsert_info_locs(info_id, locales)
    loc_ids = upsert_version_locs(vid, locales)
    upsert_review(vid)
    upsert_iap(locales)
    upload_screens(loc_ids)
    Path("/tmp/asc-1.1-version-id.txt").write_text(vid)
    print("METADATA_OK", vid)


if __name__ == "__main__":
    main()
