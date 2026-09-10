# App Store Connect — Mind Cipher 1.2 (Spy Dossier)

| | |
|---|---|
| Apple ID | `6777428188` |
| Bundle ID | `Jason-Wang.CodeBreaker` |
| Version | **1.2** — ASC version id `39eb1bbb-0e08-4b6e-8878-5d9517e17784` |
| Build | **6** (Release archive `build-asc/MindCipher.xcarchive`, uploaded and submitted for review 2026-09-10; adds the weekday daily ladder — build 5 had the new icon only, build 4 the earlier pouch icon) |
| Live before | 1.1 (3) |
| Release type | After approval |

## What changed since 1.1 (drives the copy)

- Full "spy dossier" restyle: paper skins, typewriter type, rubber stamps, filing-cabinet level select with kraft archive pouches, case reports with share cards, index-page headers. Vocabulary: cases / case files / informants / closed.
- New app icon: the three ink feedback marks — filled dot, ring, dash — on cream paper.
- Feedback marks are ink only — filled dot (exact), ring (misplaced), dash (absent). Optional **Shape marks** setting (Settings → Colorblind) gives every peg its own outline. Pegs use an Okabe-Ito palette.
- Today's Case: Top Secret (lie) days, home-screen widget, localized share cards; new players open on a first lie.
- Two themes: Dossier and Night Desk.
- Dynamic Type and RTL pass.

Store copy for all 12 locales lives in `docs/asc_1.2.json` (description, promotionalText, whatsNew). Name, subtitle and keywords are unchanged from 1.1 (`docs/ASC_1.1.md`, `docs/aso_1.1.json`). The old description said "teal circle, orange triangle, black cross" — that is no longer true and has been replaced everywhere.

## Screenshots

8 shots × 12 locales, 1284×2778 (`APP_IPHONE_65`), produced by `docs/export_dossier_screenshots.py` into `assets/asc-dossier/<locale>/`:

1. `01_case` — case page mid-analysis (classic challenge, seed 20260908)
2. `02_report` — stamped case report
3. `03_lie` — Top Secret lie case
4. `04_cabinet` — filing cabinet (classic level select, seeded stars)
5. `05_night` — Night Desk skin, case page
6. `06_shapes` — Shape Marks (colour-blind) on the case page
7. `07_daily` — Today's Case calendar (seeded six-day streak)
8. `08_home` — home index page

The first three carry the pitch (search results show 1–3); the rest are for people who swipe. Banners come from `docs/asc_dossier_banners.json`; seeded progress lives in `seedStoreScreenshotDefaults()` (DEBUG only, `-storeScreenshots`). `extra` re-captures only shots 4–8.

## Pipeline

```bash
# 1. Screenshots (needs a booted simulator + idb; ~4 min per locale)
SIM_UDID=<udid> /tmp/asc-venv/bin/python docs/export_dossier_screenshots.py all

# 2. Archive + export + upload (API key auth so no Xcode account is needed)
xcodebuild -project CodeBreaker.xcodeproj -scheme CodeBreaker -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build-asc/MindCipher.xcarchive \
  -derivedDataPath build-asc/DerivedData -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build-asc/MindCipher.xcarchive \
  -exportOptionsPlist build-asc/ExportOptions.plist -exportPath build-asc/export -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_Y8W69V3U7C.p8 \
  -authenticationKeyID Y8W69V3U7C -authenticationKeyIssuerID 6fba9ede-5341-4112-a55f-d00d4e7cb05b
xcrun altool --upload-app --type ios -f build-asc/export/CodeBreaker.ipa \
  --apiKey Y8W69V3U7C --apiIssuer 6fba9ede-5341-4112-a55f-d00d4e7cb05b

# 3. App Store Connect (idempotent steps)
/tmp/asc-venv/bin/python docs/release_asc_1.2.py version       # create 1.2, copyright, release type
/tmp/asc-venv/bin/python docs/release_asc_1.2.py metadata      # push docs/asc_1.2.json
/tmp/asc-venv/bin/python docs/release_asc_1.2.py screenshots   # replace 6.5" sets
/tmp/asc-venv/bin/python docs/release_asc_1.2.py build         # attach build 6 once processed
/tmp/asc-venv/bin/python docs/release_asc_1.2.py status
/tmp/asc-venv/bin/python docs/release_asc_1.2.py submit        # explicit: sends for review
```

The venv needs `pyjwt cryptography requests pillow arabic-reshaper python-bidi`.

## Review notes

Unchanged from 1.1 except vocabulary; the review-notes block in `docs/ASC_1.1.md` still applies (Classic Missions → Classic cases, Lie Missions → Lie cases, hints → informants). IAP product IDs are unchanged.
