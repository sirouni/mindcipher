# App Store Screenshots & Marketing Design Specs

## App Store Screenshots

### Dimensions
- **Target**: 1284 x 2778 px (iPhone 6.5" display)
- **Source simulator**: iPhone 16e (1170 x 2532 px)
- **Scaling**: `ffmpeg -vf "scale=1284:2778"` or crop/fit as needed

### Layout Structure

```
+---------------------------+
|     Top Banner (218px)    |
|     dark (#1B2640)        |
+---------------------------+
|                           |
|   App Content (2362px)    |
|   (scaled screenshot)     |
|                           |
+---------------------------+
|   Bottom Bar (198px)      |
|   dark (#1B2640)          |
+---------------------------+
```

Total: 218 + 2362 + 198 = 2778px

### Banner Text Style
- **Title**: White, 72px, Helvetica Bold, centered horizontally, y=40
- **Subtitle**: Light blue (#7BC8E8), 42px, Helvetica, centered horizontally, y=130
- Both vertically centered within the 218px dark banner area

### Color Palette
| Element | Color |
|---------|-------|
| Dark background (banner/bar) | `#1B2640` |
| Teal accent (app UI, not banner) | `#2FBFAE` |
| Title text | `#FFFFFF` |
| Subtitle text | `#7BC8E8` |
| App background | `#E8EFF5` (light blue-gray) |

### Screenshot List

| File | Title | Subtitle |
|------|-------|----------|
| `02_daily_challenge.png` | Daily Challenge | A new puzzle every day |
| `03_campaign.png` | 480 Levels | From beginner to master |
| `04_gameplay.png` | Crack the Code | Deduce the secret combination |
| `05_smart_notes.png` | Smart Notes | Track your deductions |
| `07_lie_missions.png` | Lie Mode | One feedback is always fake |
| `08_duel_mode.png` | Duel Mode | Challenge a friend |
| `09_challenge_friend.png` | Challenge a Friend | Share custom puzzles |
| `achievements.png` | Share with Friends | Show off your achievements |
| `store_iap.png` | (IAP review screenshot) | N/A |

### Build Command Template

```bash
# 1. Take raw screenshot
xcrun simctl io <UDID> screenshot /tmp/raw.png

# 2. Scale content to fit between bars (1284x2362)
ffmpeg -y -i /tmp/raw.png -vf "scale=1284:2362" /tmp/content.png

# 3. Create top banner (218px dark)
ffmpeg -y -f lavfi -i "color=c=0x1B2640:s=1284x218:d=1" \
  -frames:v 1 /tmp/top_banner.png

# 4. Create bottom bar (198px dark)
ffmpeg -y -f lavfi -i "color=c=0x1B2640:s=1284x198:d=1" \
  -frames:v 1 /tmp/bottom_bar.png

# 5. Stack: top + content + bottom
ffmpeg -y \
  -i /tmp/top_banner.png \
  -i /tmp/content.png \
  -i /tmp/bottom_bar.png \
  -filter_complex "[0:v][1:v][2:v]vstack=inputs=3" \
  -frames:v 1 /tmp/stacked.png

# 6. Add text
ffmpeg -y -i /tmp/stacked.png \
  -vf "drawtext=text='TITLE':fontsize=72:fontcolor=white:x=(w-text_w)/2:y=40:fontfile=/System/Library/Fonts/Helvetica.ttc,\
drawtext=text='Subtitle here':fontsize=42:fontcolor=0x7BC8E8:x=(w-text_w)/2:y=130:fontfile=/System/Library/Fonts/Helvetica.ttc" \
  -frames:v 1 /path/to/output.png
```

---

## App Preview Video

### Specs
- **Dimensions**: 886 x 1920 px (iPhone 6.5" portrait)
- **Duration**: Up to 30 seconds
- **Format**: H.264 video + AAC audio (silent track required)
- **File**: `assets/app_preview.mp4`

### Audio Requirement
App Store Connect requires an audio track even if silent:
```bash
ffmpeg -y -i input.mp4 \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -c:v copy -c:a aac -b:a 128k -shortest \
  output.mp4
```

---

## URLs & Accounts

### App Store Connect
- **App ID**: 6777428188
- **App Store URL**: https://apps.apple.com/app/mind-cipher/id6777428188
- **Bundle ID**: Jason-Wang.CodeBreaker
- **SKU**: codebreaker-ios-001

### Marketing Website (GitHub Pages)
- **Marketing**: https://sirouni.github.io/mindcipher/
- **Support**: https://sirouni.github.io/mindcipher/support.html
- **Privacy Policy**: https://sirouni.github.io/mindcipher/privacy.html

### Sandbox Testing Account
- **Email**: mindcipher.sandbox01@outlook.com
- **Password**: Mc$andbox2026Xk!
- **Region**: United States

### In-App Purchase Product IDs
| Product | ID | Type | Price |
|---------|-----|------|-------|
| Pro Unlock | `com.codebreaker.app.pro` | Non-consumable | $2.99 |
| 5 Hint Coins | `com.codebreaker.app.hints5` | Consumable | $0.99 |
| 15 Hint Coins | `com.codebreaker.app.hints15` | Consumable | $1.99 |
| 50 Hint Coins | `com.codebreaker.app.hints50` | Consumable | $4.99 |

### Game Center
- **Leaderboard ID**: `com.codebreaker.app.total`

---

## Marketing Website Structure

```
docs/
├── index.html       (Marketing landing page)
├── support.html     (Support/FAQ page)
├── privacy.html     (Privacy Policy)
└── DESIGN_SPECS.md  (This file)
```

### Design Notes
- Clean, minimal design matching app aesthetic
- Hero section with app icon and key features
- Screenshots gallery
- Download link to App Store
- Support page with FAQ and contact info
