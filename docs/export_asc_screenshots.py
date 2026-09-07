#!/usr/bin/env python3
"""Capture and composite App Store screenshots for every localization."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from datetime import date
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path("/Users/wangxiao/Projects/CodeBreaker")
BANNERS = json.loads((ROOT / "docs/asc_screenshot_banners.json").read_text())
OUT = ROOT / "assets/asc"
RAW = ROOT / "assets/asc/_raw"
BUNDLE = "Jason-Wang.CodeBreaker"
UDID = os.environ.get("SIM_UDID", "60971CD4-1C50-456D-A355-9FDC93858987")

W, H = 1284, 2778
BANNER_H, BAR_H = 218, 198
CONTENT_H = H - BANNER_H - BAR_H
NAVY = (27, 38, 64, 255)
WHITE = (255, 255, 255, 255)
SUB = (123, 200, 232, 255)

LANGS = [
    "en", "zh", "zh-Hant", "ja", "ko", "es",
    "ar", "de", "fr", "he", "pt", "tr",
]


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    kwargs.setdefault("timeout", 20)
    try:
        return subprocess.run(cmd, check=False, capture_output=True, text=True, **kwargs)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(cmd, 124, "", "timeout")


def idb(*args: str) -> subprocess.CompletedProcess:
    # idb wants flags after the subcommand: `idb ui tap --udid UDID x y`
    cmd = ["idb", *args]
    if "--udid" not in cmd:
        cmd += ["--udid", UDID]
    return run(cmd)


def simctl(*args: str) -> subprocess.CompletedProcess:
    return run(["xcrun", "simctl", *args])


def describe() -> dict:
    p = idb("ui", "describe-all", "--json", "--nested")
    if p.returncode != 0 or not p.stdout.strip():
        return {}
    try:
        data = json.loads(p.stdout)
    except json.JSONDecodeError:
        return {}
    return data[0] if isinstance(data, list) and data else data


def walk(node, acc=None):
    if acc is None:
        acc = []
    if isinstance(node, list):
        for child in node:
            walk(child, acc)
        return acc
    if not isinstance(node, dict):
        return acc
    acc.append(node)
    for key in ("children", "AXChildren"):
        if key in node:
            walk(node[key], acc)
    return acc


def frame_of(el: dict):
    fr = el.get("frame") or el.get("AXFrame") or {}
    if isinstance(fr, str):
        return None
    x = fr.get("x") or fr.get("X")
    y = fr.get("y") or fr.get("Y")
    w = fr.get("width") or fr.get("Width")
    h = fr.get("height") or fr.get("Height")
    if None in (x, y, w, h):
        return None
    return float(x), float(y), float(w), float(h)


def label_of(el: dict) -> str:
    for key in ("AXLabel", "label", "AXValue", "value", "AXUniqueId", "AXIdentifier"):
        v = el.get(key)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def ident_of(el: dict) -> str:
    for key in ("AXUniqueId", "AXIdentifier", "identifier"):
        v = el.get(key)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def find_all(pred):
    return [el for el in walk(describe()) if pred(el)]


def tap_el(el: dict) -> bool:
    fr = frame_of(el)
    if not fr:
        return False
    x, y, w, h = fr
    idb("ui", "tap", str(int(x + w / 2)), str(int(y + h / 2)))
    time.sleep(0.45)
    return True


def tap_label(*needles: str, ident: str | None = None, exact: bool = False) -> bool:
    needles_l = [n.lower() for n in needles]
    els = find_all(lambda _: True)
    if ident:
        for el in els:
            if ident_of(el) == ident:
                return tap_el(el)
    for el in els:
        lab = label_of(el).lower()
        if lab and any(lab == n for n in needles_l):
            return tap_el(el)
    if not exact:
        for el in els:
            lab = label_of(el).lower()
            if lab and any(n in lab for n in needles_l if len(n) >= 3):
                return tap_el(el)
    return False


def wait_label(*needles: str, timeout: float = 8) -> bool:
    end = time.time() + timeout
    needles_l = [n.lower() for n in needles]
    while time.time() < end:
        for el in find_all(lambda _: True):
            lab = label_of(el).lower()
            if any(n in lab for n in needles_l):
                return True
        time.sleep(0.35)
    return False


def screenshot(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    simctl("io", UDID, "screenshot", str(path))


def terminate():
    simctl("terminate", UDID, BUNDLE)
    time.sleep(0.4)


def defaults_write(*args: str):
    simctl("spawn", UDID, "defaults", "write", BUNDLE, *args)


def seed_defaults(lang: str):
    defaults_write("hasSeenTutorial", "-bool", "true")
    defaults_write("hasSeenLieTaste", "-bool", "true")
    defaults_write(f"daily_{date.today().isoformat()}", "-bool", "false")
    defaults_write("store_is_pro", "-bool", "true")
    defaults_write("settings_language", "-string", lang)
    levels = [str(i) for i in range(1, 161)]
    simctl("spawn", UDID, "defaults", "write", BUNDLE, "completedLevels", "-array", *levels)
    simctl("spawn", UDID, "defaults", "write", BUNDLE, "lie_completedLevels", "-array", *levels)
    defaults_write("stats_gamesPlayed", "-int", "15")
    defaults_write("stats_gamesWon", "-int", "12")
    defaults_write("stats_currentStreak", "-int", "4")
    defaults_write("stats_bestStreak", "-int", "6")
    defaults_write("stats_totalAttempts", "-int", "40")
    simctl(
        "spawn",
        UDID,
        "defaults",
        "write",
        BUNDLE,
        "achievements_unlocked",
        "-array",
        "first_win",
        "play_5",
        "play_10",
        "win_10",
    )


APPLE = {
    "en": ("en", "en_US"),
    "zh": ("zh-Hans", "zh_CN"),
    "zh-Hant": ("zh-Hant", "zh_TW"),
    "ja": ("ja", "ja_JP"),
    "ko": ("ko", "ko_KR"),
    "es": ("es", "es_ES"),
    "ar": ("ar", "ar_AE"),
    "de": ("de", "de_DE"),
    "fr": ("fr", "fr_FR"),
    "he": ("he", "he_IL"),
    "pt": ("pt-BR", "pt_BR"),
    "tr": ("tr", "tr_TR"),
}


def screen_labels() -> str:
    return " ".join(label_of(el) for el in find_all(lambda _: True))


def dismiss_open_alert(accept: bool = False):
    for _ in range(4):
        text = screen_labels()
        has_alert = any(
            s in text
            for s in (
                "Open in", "Open “", "打开", "打開", "Öffnen", "Ouvrir",
                "열기", "فتح", "Abrir en",
            )
        ) or ("Cancel" in text and "Open" in text)
        if not has_alert:
            return
        if accept and tap_label("Open", exact=True):
            time.sleep(0.5)
            continue
        if tap_label("Cancel", "取消", "キャンセル", "취소", "Annuler", "Abbrechen", "ביטול", "İptal", "Cancelar", exact=True):
            time.sleep(0.45)
            continue
        idb("ui", "tap", "127" if not accept else "271", "474")
        time.sleep(0.45)


def launch(lang: str):
    terminate()
    seed_defaults(lang)
    apple, locale = APPLE[lang]
    simctl(
        "launch",
        UDID,
        BUNDLE,
        "-isPro",
        "-storeScreenshots",
        "-hasSeenTutorial",
        "YES",
        "-settings_language",
        lang,
        "-store_is_pro",
        "YES",
        "-AppleLanguages",
        f"({apple})",
        "-AppleLocale",
        locale,
        "-AppleICUCalendar",
        "gregorian",
    )
    time.sleep(1.8)
    dismiss_open_alert(accept=False)


def at_home() -> bool:
    return any(ident_of(el) == "home.daily" for el in find_all(lambda _: True))


def go_home(lang: str = "en"):
    back_x = "360" if lang in {"ar", "he"} else "40"
    for _ in range(8):
        dismiss_open_alert(accept=False)
        try:
            if at_home():
                return True
        except Exception:
            pass
        if tap_label("Back", exact=True):
            time.sleep(0.3)
        else:
            idb("ui", "tap", back_x, "72")
            time.sleep(0.32)
        try:
            if at_home():
                return True
        except Exception:
            pass
    return False


COLORS = {
    "Red": ["Red", "红", "紅", "赤", "빨강", "Rojo", "أحمر", "Rot", "Rouge", "אדום", "Vermelho", "Kırmızı"],
    "Green": ["Green", "绿", "綠", "緑", "초록", "Verde", "أخضر", "Grün", "Vert", "ירוק", "Yeşil"],
    "Blue": ["Blue", "蓝", "藍", "青", "파랑", "Azul", "أزرق", "Blau", "Bleu", "כחול", "Mavi"],
    "Yellow": ["Yellow", "黄", "黃", "黄", "노랑", "Amarillo", "أصفر", "Gelb", "Jaune", "צהוב", "Amarelo", "Sarı"],
    "Purple": ["Purple", "紫", "보라", "Morado", "بنفسجي", "Lila", "Violet", "סגול", "Roxo", "Mor"],
    "Orange": ["Orange", "橙", "オレンジ", "주황", "Naranja", "برتقالي", "כתום", "Laranja", "Turuncu"],
    "Cyan": ["Cyan", "青", "シアン", "청록", "Cian", "سماوي", "ציאן", "Ciano", "Camgöbeği"],
    "Pink": ["Pink", "粉", "ピンク", "분홍", "Rosa", "وردي", "Rose", "ורוד", "Pembe"],
}


def tap_color(name: str) -> bool:
    ident = f"peg.{name.lower()}"
    if tap_label(ident=ident):
        return True
    aliases = COLORS.get(name, [name])
    return tap_label(*aliases, exact=True) or tap_label(*aliases)


def guess(colors: list[str], submit: str):
    for color in colors:
        if not tap_color(color):
            print(f"  missing color {color}", flush=True)
        time.sleep(0.15)
    if not tap_label(submit, "Submit", "提交", "送信", "제출", "Enviar", "إرسال", "Senden", "Valider", "שלח", "Gönder"):
        tap_label("Submit")
    time.sleep(0.55)


def capture_lang(lang: str):
    meta = BANNERS["locales"][lang]
    start = meta["start"]
    submit = meta["submit"]
    medium = meta["medium"]
    first = meta["firstCrack"]
    dest = RAW / lang
    dest.mkdir(parents=True, exist_ok=True)

    print(f"\n=== {lang} ===", flush=True)
    launch(lang)
    dismiss_open_alert(accept=False)
    wait_label("Daily", "每日", "每日挑戰", "デイリー", "일일", timeout=8)
    dismiss_open_alert(accept=False)
    if not at_home():
        print("  not on home after launch", flush=True)
        go_home(lang)
        dismiss_open_alert(accept=False)

    tap_label(ident="home.daily")
    time.sleep(0.8)
    screenshot(dest / "07_daily.png")
    print("  shot 07_daily", flush=True)
    go_home(lang)

    tap_label(ident="home.classic")
    time.sleep(0.6)
    for _ in range(4):
        tap_label("Next tier", exact=True)
        time.sleep(0.28)
    screenshot(dest / "05_campaign.png")
    print("  shot 05_campaign", flush=True)

    tap_label("161", exact=True)
    time.sleep(0.45)
    tap_label(start, exact=True) or tap_label("Start", "开始", "開始", "始める", "시작", "Empezar", "ابدأ", "Commencer", "התחל", "Começar", "Başla")
    if not wait_label("Submit", "提交", "送信", "제출", "Enviar", "إرسال", "Senden", "Valider", "שלח", "Gönder", timeout=6):
        print("  no submit after classic start", flush=True)
    guess(["Red", "Green", "Blue", "Yellow", "Purple"], submit)
    guess(["Orange", "Cyan", "Pink", "Red", "Green"], submit)
    time.sleep(0.35)
    screenshot(dest / "01_gameplay.png")
    print("  shot 01_gameplay", flush=True)
    tap_label("Notes", exact=True)
    time.sleep(0.55)
    screenshot(dest / "03_notes.png")
    print("  shot 03_notes", flush=True)
    tap_label("Notes", exact=True)
    time.sleep(0.3)
    go_home(lang)

    tap_label(ident="home.lie")
    time.sleep(0.6)
    for _ in range(4):
        tap_label("Next tier", exact=True)
        time.sleep(0.28)
    tap_label("161", exact=True)
    time.sleep(0.45)
    tap_label(start, exact=True) or tap_label("Start", "开始", "開始", "始める", "시작", "Empezar", "ابدأ", "Commencer", "התחל", "Começar", "Başla")
    time.sleep(2.2)
    if not wait_label("Submit", "提交", "送信", "제출", "Enviar", "إرسال", "Senden", "Valider", "שלח", "Gönder", timeout=6):
        print("  no submit after lie start", flush=True)
    guess(["Pink", "Cyan", "Blue", "Yellow", "Red"], submit)
    guess(["Green", "Blue", "Yellow", "Red", "Orange"], submit)
    time.sleep(0.35)
    screenshot(dest / "02_lie.png")
    print("  shot 02_lie", flush=True)
    go_home(lang)

    tap_label(ident="home.duel") or tap_label(
        "Duel Mode", "双人对战", "雙人對戰", "対戦モード", "대전 모드", "Modo duelo",
        "وضع المبارزة", "Duellmodus", "Mode duel", "מצב דו-קרב", "Düello modu",
    )
    time.sleep(0.7)
    tap_label(ident="duel.diff.medium") or tap_label(medium, exact=True) or tap_label(medium)
    time.sleep(0.35)
    screenshot(dest / "04_duel.png")
    print("  shot 04_duel", flush=True)
    go_home(lang)

    tap_label(ident="home.achievements") or tap_label(
        "Achievements", "成就", "実績", "업적", "Logros", "الإنجازات",
        "Erfolge", "Succès", "הישגים", "Conquistas", "Başarımlar",
    )
    time.sleep(0.8)
    tap_label(ident="achieve.first_win") or tap_label(first, exact=True) or tap_label(first) or tap_label("First Crack")
    time.sleep(0.4)
    tap_label(ident="achieve.first_win")
    time.sleep(0.9)
    screenshot(dest / "08_achievements.png")
    print("  shot 08_achievements", flush=True)
    go_home(lang)

    simctl(
        "openurl",
        UDID,
        "codebreaker://challenge?s=42424242&l=5&c=8&a=10&d=0&m=0&f=Alex",
    )
    time.sleep(0.8)
    dismiss_open_alert(accept=True)
    time.sleep(0.9)
    screenshot(dest / "06_challenge.png")
    print("  shot 06_challenge", flush=True)
    terminate()
    print(f"done raw {lang}", flush=True)


def font_for(lang: str, size: int) -> ImageFont.FreeTypeFont:
    paths = {
        "zh": "/System/Library/Fonts/STHeiti Medium.ttc",
        "zh-Hant": "/System/Library/Fonts/STHeiti Medium.ttc",
        "ja": "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "ko": "/System/Library/Fonts/AppleSDGothicNeo.ttc",
        "ar": "/System/Library/Fonts/GeezaPro.ttc",
        "he": "/System/Library/Fonts/ArialHB.ttc",
    }
    latin = "/System/Library/Fonts/Helvetica.ttc"
    path = paths.get(lang, latin)
    try:
        return ImageFont.truetype(path, size=size, index=0)
    except OSError:
        return ImageFont.truetype(latin, size=size)


def shape_text(text: str, lang: str) -> str:
    if lang == "ar":
        try:
            import arabic_reshaper
            from bidi.algorithm import get_display
            return get_display(arabic_reshaper.reshape(text))
        except Exception:
            return text
    if lang == "he":
        try:
            from bidi.algorithm import get_display
            return get_display(text)
        except Exception:
            return text
    return text


def composite(lang: str):
    meta = BANNERS["locales"][lang]
    asc = meta["asc"]
    dest = OUT / asc
    dest.mkdir(parents=True, exist_ok=True)
    title_font = font_for(lang, 64)
    sub_font = font_for(lang, 36)
    for key in BANNERS["order"]:
        raw = RAW / lang / f"{key}.png"
        if not raw.exists():
            print(f"skip missing {raw}")
            continue
        src = Image.open(raw).convert("RGBA")
        content = src.resize((W, CONTENT_H), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (W, H), NAVY)
        canvas.paste(content, (0, BANNER_H))
        draw = ImageDraw.Draw(canvas)
        title, subtitle = meta["banners"][key]
        title = shape_text(title, lang)
        subtitle = shape_text(subtitle, lang)
        tb = draw.textbbox((0, 0), title, font=title_font)
        sb = draw.textbbox((0, 0), subtitle, font=sub_font)
        draw.text(((W - (tb[2] - tb[0])) / 2, 38), title, font=title_font, fill=WHITE)
        draw.text(((W - (sb[2] - sb[0])) / 2, 124), subtitle, font=sub_font, fill=SUB)
        out = dest / f"{key}.png"
        canvas.convert("RGB").save(out, "PNG", optimize=True)
        print(f"wrote {out.relative_to(ROOT)}")


def main():
    langs = sys.argv[1:] or LANGS
    mode = "all"
    if langs and langs[0] in {"capture", "composite", "all"}:
        mode = langs[0]
        langs = langs[1:] or LANGS
    if mode in {"capture", "all"}:
        for lang in langs:
            capture_lang(lang)
    if mode in {"composite", "all"}:
        for lang in langs:
            composite(lang)


if __name__ == "__main__":
    main()
