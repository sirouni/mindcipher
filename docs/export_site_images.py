"""Derive the landing-site images from the App Store capture set.

    python3 docs/export_site_images.py

Reads the raw device captures in assets/asc-dossier/_raw/<lang>/ (1206×2622) and
writes docs/images/shots/<site-lang>/{case,lie,daily}.jpg at 480px wide, plus the
512px app icon (docs/images/icon.png) from the asset catalog.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets/asc-dossier/_raw"
OUT = ROOT / "docs/images"

# site locale → raw capture folder
LANGS = {
    "en": "en", "zh-Hans": "zh", "zh-Hant": "zh-Hant", "ja": "ja", "ko": "ko",
    "es": "es", "ar": "ar", "de": "de", "fr": "fr", "he": "he", "pt": "pt", "tr": "tr",
}
SHOTS = {"case": "01_case.png", "lie": "03_lie.png", "daily": "07_daily.png"}
WIDTH = 480


def main():
    for site, raw in LANGS.items():
        dst = OUT / "shots" / site
        dst.mkdir(parents=True, exist_ok=True)
        for name, src in SHOTS.items():
            im = Image.open(RAW / raw / src).convert("RGB")
            h = round(im.height * WIDTH / im.width)
            im.resize((WIDTH, h), Image.LANCZOS).save(dst / f"{name}.jpg", quality=82, optimize=True, progressive=True)
        print(site, "ok", f"{WIDTH}x{h}")
    icon = Image.open(ROOT / "CodeBreaker/Assets.xcassets/AppIcon.appiconset/AppIcon.png").convert("RGB")
    icon.resize((512, 512), Image.LANCZOS).save(OUT / "icon.png", optimize=True)
    print("icon ok")


if __name__ == "__main__":
    main()
