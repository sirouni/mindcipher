"""Build the localized landing pages for GitHub Pages.

    python3 docs/build_site.py

Reads docs/templates/index.html and docs/i18n/<code>.json, writes docs/index.html
(English, x-default) plus docs/<code>/index.html for every other locale, with
hreflang alternates, dir="rtl" where needed, per-locale App Store screenshots and
a language index in the footer. Do not edit the generated index.html files by hand.
"""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SITE = "https://sirouni.github.io/mindcipher/"
STORE = "https://apps.apple.com/app/mind-cipher/id6777428188"

# folder name → (hreflang code, og:locale). English lives at the site root.
LOCALES = [
    ("en", "en", "en_US"),
    ("zh-Hans", "zh-Hans", "zh_CN"),
    ("zh-Hant", "zh-Hant", "zh_TW"),
    ("ja", "ja", "ja_JP"),
    ("ko", "ko", "ko_KR"),
    ("es", "es", "es_ES"),
    ("ar", "ar", "ar_SA"),
    ("de", "de", "de_DE"),
    ("fr", "fr", "fr_FR"),
    ("he", "he", "he_IL"),
    ("pt", "pt-BR", "pt_BR"),
    ("tr", "tr", "tr_TR"),
]

RAW_KEYS = {"alternates", "langs"}  # template placeholders written as {{{key}}}


def url_for(folder):
    return SITE if folder == "en" else f"{SITE}{folder}/"


def render(template, ctx):
    def raw(m):
        return str(ctx[m.group(1)])

    def esc(m):
        return html.escape(str(ctx[m.group(1)]), quote=True)

    out = re.sub(r"\{\{\{(\w+)\}\}\}", raw, template)
    return re.sub(r"\{\{(\w+)\}\}", esc, out)


def main():
    template = (ROOT / "templates/index.html").read_text()
    strings = {f: json.loads((ROOT / f"i18n/{f}.json").read_text()) for f, _, _ in LOCALES}
    required = set(strings["en"])
    for f, s in strings.items():
        missing = required - set(s)
        assert not missing, f"{f}: missing {sorted(missing)}"

    alternates = "\n".join(
        f'  <link rel="alternate" hreflang="{code}" href="{url_for(f)}">' for f, code, _ in LOCALES
    ) + f'\n  <link rel="alternate" hreflang="x-default" href="{SITE}">'

    for folder, code, og in LOCALES:
        s = dict(strings[folder])
        base = "" if folder == "en" else "../"
        langs = []
        for f2, code2, _ in LOCALES:
            name = html.escape(strings[f2]["name"])
            href = "index.html" if f2 == "en" else f"{f2}/index.html"
            href = base + href
            if f2 == folder:
                langs.append(f'      <a href="{href}" lang="{code2}" aria-current="page">{name}</a>')
            else:
                langs.append(f'      <a href="{href}" lang="{code2}" hreflang="{code2}">{name}</a>')
        s.update({
            "base": base,
            "home": "index.html",
            "site": SITE,
            "canonical": url_for(folder),
            "og_locale": og,
            "store": STORE if folder == "en" else f"{STORE}?l={s['store_l']}",
            "shots": folder,
            "alternates": alternates,
            "langs": "\n".join(langs),
        })
        out = ROOT / ("index.html" if folder == "en" else f"{folder}/index.html")
        out.parent.mkdir(exist_ok=True)
        out.write_text(render(template, s))
        print(out.relative_to(ROOT), s["lang"], s["dir"])


if __name__ == "__main__":
    main()
