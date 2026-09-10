#!/usr/bin/env python3
"""Capture and composite the dossier-style App Store screenshots (4 shots x 12 locales).

Order (from the redesign plan): case page -> case report -> lie day -> home.

Usage:
    python3 docs/export_dossier_screenshots.py [capture|composite|all] [lang ...]

Environment:
    SIM_UDID   booted simulator to drive (idb companion must be able to attach)

Requires: Pillow, arabic-reshaper, python-bidi (a venv is fine), idb, xcrun.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BANNERS = json.loads((ROOT / "docs/asc_dossier_banners.json").read_text())
OUT = ROOT / "assets/asc-dossier"
RAW = OUT / "_raw"
BUNDLE = "Jason-Wang.CodeBreaker"
UDID = os.environ.get("SIM_UDID", "AD3A9B22-523E-4E0C-818A-AAB62191AF01")

# 6.7" App Store size.
W, H = 1284, 2778
BANNER_H = 330

PAPER = (241, 233, 214)
FOLDER = (232, 222, 197)
INK = (43, 35, 24)
INK_FADED = (122, 110, 90)
STAMP = (184, 50, 43)

LANGS = ["en", "zh", "zh-Hant", "ja", "ko", "es", "ar", "de", "fr", "he", "pt", "tr"]
RTL = {"ar", "he"}

# Deterministic seeds: any non-zero value works, these just give a pleasant reveal.
CLASSIC_SEED = 20260908
LIE_SEED = 19470601
PEG_IDS = ["red", "green", "blue", "yellow", "purple", "orange", "cyan", "ink"]

APPLE = {
    "en": ("en", "en_US"), "zh": ("zh-Hans", "zh_CN"), "zh-Hant": ("zh-Hant", "zh_TW"),
    "ja": ("ja", "ja_JP"), "ko": ("ko", "ko_KR"), "es": ("es", "es_ES"), "ar": ("ar", "ar_AE"),
    "de": ("de", "de_DE"), "fr": ("fr", "fr_FR"), "he": ("he", "he_IL"), "pt": ("pt-BR", "pt_BR"),
    "tr": ("tr", "tr_TR"),
}


# --------------------------------------------------------------------------- strings

_L10N_CACHE: dict[str, dict[str, str]] = {}


def l10n(key: str) -> dict[str, str]:
    """Pull one key's 12 translations straight out of L10n.swift."""
    if key in _L10N_CACHE:
        return _L10N_CACHE[key]
    src = (ROOT / "CodeBreaker/L10n.swift").read_text()
    m = re.search(r'"%s":\s*Tr\((.*?)\)\.dict' % re.escape(key), src, re.S)
    if not m:
        raise KeyError(key)
    pairs = re.findall(r'(\w+):\s*"((?:[^"\\]|\\.)*)"', m.group(1))
    table = {k: v.encode().decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in v else v
             for k, v in pairs}
    table["zh-Hant"] = table.pop("hant")
    _L10N_CACHE[key] = table
    return table


# --------------------------------------------------------------------------- game maths

MASK = (1 << 64) - 1


class XorShift:
    def __init__(self, seed: int):
        self.s = seed if seed else 1

    def next(self) -> int:
        s = self.s
        s ^= (s << 13) & MASK
        s ^= s >> 7
        s ^= (s << 17) & MASK
        self.s = s
        return s


def secret_for(seed: int, length: int, colors: int, lie: bool) -> list[int]:
    rng = XorShift(seed)
    if lie:
        optimal = {3: 4, 4: 6, 5: 8}.get(length, 8)
        rng.next() % max(1, optimal - 1)  # lie attempt draw, discarded
    pool = list(range(colors))
    code = []
    for _ in range(length):
        idx = rng.next() % len(pool)
        code.append(pool.pop(idx))
    return code


def scripted_guesses(code: list[int], colors: int) -> list[list[int]]:
    """Two near misses then the answer: (1 exact, 2 misplaced, 1 absent) and (2 exact, 2 misplaced)."""
    spare = next(c for c in range(colors) if c not in code)
    g1 = [code[1], code[0], code[2], spare]
    g2 = [code[0], code[1], code[3], code[2]]
    return [g1, g2, list(code)]


# --------------------------------------------------------------------------- simulator driving

def run(cmd: list[str], timeout: float = 25) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(cmd, 124, "", "timeout")


def idb(*args: str) -> subprocess.CompletedProcess:
    return run(["idb", *args, "--udid", UDID])


def simctl(*args: str) -> subprocess.CompletedProcess:
    return run(["xcrun", "simctl", *args])


def describe() -> list[dict]:
    p = idb("ui", "describe-all", "--json", "--nested")
    if p.returncode != 0 or not p.stdout.strip():
        return []
    try:
        data = json.loads(p.stdout)
    except json.JSONDecodeError:
        return []
    acc: list[dict] = []

    def walk(node):
        if isinstance(node, list):
            for n in node:
                walk(n)
        elif isinstance(node, dict):
            acc.append(node)
            for key in ("children", "AXChildren"):
                if key in node:
                    walk(node[key])

    walk(data)
    return acc


def frame_of(el: dict):
    fr = el.get("frame") or {}
    if not isinstance(fr, dict):
        return None
    try:
        return float(fr["x"]), float(fr["y"]), float(fr["width"]), float(fr["height"])
    except (KeyError, TypeError, ValueError):
        return None


def label_of(el: dict) -> str:
    for key in ("AXLabel", "AXValue", "AXUniqueId"):
        v = el.get(key)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def tap_el(el: dict) -> bool:
    fr = frame_of(el)
    if not fr:
        return False
    x, y, w, h = fr
    idb("ui", "tap", str(int(x + w / 2)), str(int(y + h / 2)))
    time.sleep(0.4)
    return True


def norm(text: str) -> str:
    """Case-insensitive compare that survives SwiftUI's .textCase(.uppercase) (Turkish İ -> i̇)."""
    return text.strip().lower().replace("\u0307", "")


def tap(ident: str | None = None, label: str | None = None, substring: bool = False) -> bool:
    els = describe()
    if ident:
        for el in els:
            if el.get("AXUniqueId") == ident:
                return tap_el(el)
    if label:
        want = norm(label)
        for el in els:
            lab = norm(label_of(el))
            if lab == want or (substring and want in lab):
                return tap_el(el)
    return False


def wait_for(ident: str | None = None, label: str | None = None, timeout: float = 8) -> bool:
    end = time.time() + timeout
    while time.time() < end:
        for el in describe():
            if ident and el.get("AXUniqueId") == ident:
                return True
            if label and norm(label) in norm(label_of(el)):
                return True
        time.sleep(0.35)
    return False


def dismiss_open_alert(accept: bool):
    """`simctl openurl` may raise a system "Open in Mind Cipher?" alert."""
    for _ in range(3):
        els = describe()
        labels = [label_of(e) for e in els]
        if not any(l in ("Open", "打开", "打開", "開く", "열기", "Abrir", "فتح", "Öffnen", "Ouvrir", "פתח", "Aç") for l in labels):
            return
        target = ("Open", "打开", "打開", "開く", "열기", "Abrir", "فتح", "Öffnen", "Ouvrir", "פתח", "Aç") if accept else \
                 ("Cancel", "取消", "キャンセル", "취소", "Cancelar", "إلغاء", "Abbrechen", "Annuler", "ביטול", "İptal")
        for el in els:
            if label_of(el) in target:
                tap_el(el)
                break
        time.sleep(0.4)


def screenshot(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    simctl("io", UDID, "screenshot", str(path))


def terminate():
    simctl("terminate", UDID, BUNDLE)
    time.sleep(0.4)


def defaults_write(*args: str):
    simctl("spawn", UDID, "defaults", "write", BUNDLE, *args)


def launch(lang: str):
    terminate()
    defaults_write("settings_language", "-string", lang)
    defaults_write("app_skin", "-string", "Dossier")
    defaults_write("settings_colorBlind", "-bool", "false")
    simctl("ui", UDID, "appearance", "light")
    simctl("ui", UDID, "content_size", "medium")
    simctl("status_bar", UDID, "override", "--time", "9:41", "--batteryState", "charged",
           "--batteryLevel", "100", "--wifiBars", "3", "--cellularBars", "4", "--operatorName", "")
    apple, locale = APPLE[lang]
    simctl(
        "launch", UDID, BUNDLE,
        "-isPro", "-storeScreenshots", "-hasSeenTutorial", "YES",
        "-settings_language", lang, "-store_is_pro", "YES",
        "-AppleLanguages", f"({apple})", "-AppleLocale", locale, "-AppleICUCalendar", "gregorian",
    )
    time.sleep(1.6)
    dismiss_open_alert(accept=False)
    wait_for(ident="home.daily", timeout=6)


def open_challenge(lang: str, seed: int, lie: bool):
    url = f"codebreaker://challenge?s={seed}&l=4&c=6&a=7&d=0&m={1 if lie else 0}&f=Agent%20K"
    simctl("openurl", UDID, url)
    time.sleep(0.8)
    dismiss_open_alert(accept=True)
    accept = l10n("challenge.accept")[lang]
    if not wait_for(label=accept, timeout=6):
        print(f"  accept button not found ({accept})", flush=True)
    tap(label=accept)
    time.sleep(0.8)


def play(lang: str, guesses: list[list[int]], settle: float = 0.5):
    submit = l10n("game.analyze")[lang]
    for g in guesses:
        for c in g:
            if not tap(ident=f"peg.{PEG_IDS[c]}"):
                print(f"  missing peg {PEG_IDS[c]}", flush=True)
            time.sleep(0.12)
        if not tap(label=submit):
            print(f"  submit not found ({submit})", flush=True)
        time.sleep(settle)


def capture_lang(lang: str):
    dest = RAW / lang
    dest.mkdir(parents=True, exist_ok=True)
    print(f"\n=== {lang} ===", flush=True)

    # 01 case page + 02 case report (classic challenge with a known code)
    launch(lang)
    code = secret_for(CLASSIC_SEED, 4, 6, lie=False)
    g = scripted_guesses(code, 6)
    open_challenge(lang, CLASSIC_SEED, lie=False)
    play(lang, g[:2])
    # Half-fill the tray so the evidence row reads as in-progress.
    for c in code[:2]:
        tap(ident=f"peg.{PEG_IDS[c]}")
        time.sleep(0.1)
    time.sleep(0.3)
    screenshot(dest / "01_case.png")
    print("  shot 01_case", flush=True)
    for c in code[2:]:
        tap(ident=f"peg.{PEG_IDS[c]}")
        time.sleep(0.1)
    tap(label=l10n("game.analyze")[lang])
    time.sleep(4.4)  # reveal + report animation, achievement toast gone
    screenshot(dest / "02_report.png")
    print("  shot 02_report", flush=True)

    # 03 lie day (lie challenge, two analyses in)
    launch(lang)
    code = secret_for(LIE_SEED, 4, 6, lie=True)
    g = scripted_guesses(code, 6)
    open_challenge(lang, LIE_SEED, lie=True)
    play(lang, g[:2], settle=0.9)
    time.sleep(0.4)
    screenshot(dest / "03_lie.png")
    print("  shot 03_lie", flush=True)

    # 04 home
    launch(lang)
    time.sleep(1.2)
    screenshot(dest / "04_home.png")
    print("  shot 04_home", flush=True)
    terminate()
    simctl("status_bar", UDID, "clear")


# --------------------------------------------------------------------------- compositing

def font_for(lang: str, size: int, typewriter: bool) -> ImageFont.FreeTypeFont:
    cjk = {
        "zh": "/System/Library/Fonts/STHeiti Medium.ttc",
        "zh-Hant": "/System/Library/Fonts/STHeiti Medium.ttc",
        "ja": "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "ko": "/System/Library/Fonts/AppleSDGothicNeo.ttc",
    }
    if lang in RTL:
        # GeezaPro / ArialHB lack Latin digits and the middle dot; Arial covers Arabic, Hebrew and Latin.
        path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if typewriter else "/System/Library/Fonts/Supplemental/Arial.ttf"
        index = 0
    elif lang in cjk:
        path, index = cjk[lang], 0
    elif typewriter:
        path, index = "/System/Library/Fonts/Supplemental/AmericanTypewriter.ttc", 2  # Bold face
    else:
        path, index = "/System/Library/Fonts/Helvetica.ttc", 0
    try:
        return ImageFont.truetype(path, size=size, index=index)
    except OSError:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size=size)


def shape(text: str, lang: str) -> str:
    if lang == "ar":
        import arabic_reshaper
        from bidi.algorithm import get_display
        return get_display(arabic_reshaper.reshape(text))
    if lang == "he":
        from bidi.algorithm import get_display
        return get_display(text)
    return text


def draw_stamp(canvas: Image.Image, text: str, center: tuple[int, int], size: int = 34, angle: float = -8):
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/AmericanTypewriter.ttc", size=size, index=2)
    pad_x, pad_y = int(size * 0.7), int(size * 0.35)
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bb = tmp.textbbox((0, 0), text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    w, h = tw + pad_x * 2 + 12, th + pad_y * 2 + 12
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=6, outline=STAMP + (225,), width=3)
    d.rounded_rectangle((6, 6, w - 7, h - 7), radius=4, outline=STAMP + (225,), width=5)
    d.text((pad_x + 6 - bb[0], pad_y + 6 - bb[1]), text, font=font, fill=STAMP + (225,))
    layer = layer.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(layer, (center[0] - layer.width // 2, center[1] - layer.height // 2))


def composite(lang: str):
    meta = BANNERS["locales"][lang]
    dest = OUT / meta["asc"]
    dest.mkdir(parents=True, exist_ok=True)
    rtl = lang in RTL
    title_font = font_for(lang, 88, typewriter=True)
    sub_font = font_for(lang, 40, typewriter=False)
    caption_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/AmericanTypewriter.ttc", size=26, index=0)

    for i, key in enumerate(BANNERS["order"]):
        raw = RAW / lang / f"{key}.png"
        if not raw.exists():
            print(f"skip missing {raw}")
            continue
        canvas = Image.new("RGBA", (W, H), PAPER + (255,))
        draw = ImageDraw.Draw(canvas)

        # Banner: caption, typewriter title, system subtitle, ink rule.
        margin = 72
        caption = f"CASE FILE  ·  {i + 1:02d} / {len(BANNERS['order']):02d}"
        title, subtitle = (shape(t, lang) for t in meta["banners"][key])
        cb = draw.textbbox((0, 0), caption, font=caption_font)
        # Shrink long titles (e.g. French) so they never run past the right margin.
        fit_font, size = title_font, 88
        tb = draw.textbbox((0, 0), title, font=fit_font)
        while tb[2] - tb[0] > W - 2 * margin and size > 56:
            size -= 4
            fit_font = font_for(lang, size, typewriter=True)
            tb = draw.textbbox((0, 0), title, font=fit_font)
        sb = draw.textbbox((0, 0), subtitle, font=sub_font)

        def x_for(bb):
            width = bb[2] - bb[0]
            return (W - margin - width) if rtl else margin

        draw.text((x_for(cb) - cb[0], 64 - cb[1]), caption, font=caption_font, fill=INK_FADED)
        draw.text((x_for(tb) - tb[0], 108 - tb[1]), title, font=fit_font, fill=INK)
        draw.text((x_for(sb) - sb[0], 224 - sb[1]), subtitle, font=sub_font, fill=INK_FADED)
        draw.rectangle((margin, BANNER_H - 22, W - margin, BANNER_H - 18), fill=INK)

        # Exhibit: the screenshot, scaled to fit, on folder paper with an ink border.
        src = Image.open(raw).convert("RGBA")
        avail_h = H - BANNER_H - 56
        scale = avail_h / src.height
        shot = src.resize((int(src.width * scale), avail_h), Image.Resampling.LANCZOS)
        x = (W - shot.width) // 2
        y = BANNER_H + 8
        draw.rectangle((x - 14, y - 14, x + shot.width + 14, y + shot.height + 14), fill=FOLDER, outline=INK, width=3)
        canvas.paste(shot, (x, y))
        # Lie shot gets the classified stamp, others a plain exhibit stamp.
        stamp_text = "TOP SECRET" if key == "03_lie" else ("CASE CLOSED" if key == "02_report" else "EXHIBIT A")
        sx = (x + 170) if rtl else (x + shot.width - 170)
        draw_stamp(canvas, stamp_text, (sx, y + 150), size=40, angle=-9)

        out = dest / f"{key}.png"
        canvas.convert("RGB").save(out, "PNG", optimize=True)
        print(f"wrote {out.relative_to(ROOT)}", flush=True)


def main():
    args = sys.argv[1:]
    mode = "all"
    if args and args[0] in {"capture", "composite", "all"}:
        mode, args = args[0], args[1:]
    langs = args or LANGS
    if mode in {"capture", "all"}:
        for lang in langs:
            capture_lang(lang)
    if mode in {"composite", "all"}:
        for lang in langs:
            composite(lang)


if __name__ == "__main__":
    main()
