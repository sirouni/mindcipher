# App Store Connect — Mind Cipher 1.1

Paste these fields into App Store Connect. Brand name is **Mind Cipher** (two words, with a space) in **every** localization — never `MindCipher`, never a translation. Do not mention online matchmaking.

| | |
|---|---|
| Apple ID | `6777428188` |
| Bundle ID | `Jason-Wang.CodeBreaker` |
| SKU | `codebreaker-ios-001` |
| Version | **1.1** |
| Build to upload | **3** |
| Live now | 1.0 (EN + ZH only; copy still says 120 + 120 levels) |
| Privacy | https://sirouni.github.io/mindcipher/privacy.html |
| Support | https://sirouni.github.io/mindcipher/support.html |
| Marketing | https://sirouni.github.io/mindcipher/ |

## Submit checklist

1. In App Information, add the ten new localizations listed below (keep EN-US and ZH-Hans).
2. For each locale: Name, Subtitle, Description, Keywords, What’s New. Promotional Text is optional and can change later without a new binary.
3. IAP: localize display names for Pro and the three hint packs.
4. Screenshots: upload a **dedicated 8-shot set per locale** (12 locales). Do not inherit English onto the others. First shot is gameplay, second is Lie — not Home. Output: `assets/asc/<locale>/`.
5. App Preview: optional. Hang the existing `assets/app_preview.mp4` on English only. Other locales can inherit that one video.
6. Xcode: **Product → Archive** on the **Release** scheme (1.1 / 3), then upload. Debug builds already on the phone are not this binary.
7. Review notes: paste the English block at the bottom of this file.
8. Age rating stays 4+. Game Center leaderboard `com.codebreaker.app.total` stays on.

Do not add EN-GB unless you want a duplicate. Spanish = Spain (`es-ES`). Portuguese = Brazil (`pt-BR`).

---

## Shared facts (keep every locale honest)

- 240 Classic + 240 Lie = 480 levels.
- Free: Daily, Duel, Classic 1–40, Lie 1–80, notes, earnable hints.
- Pro is **$2.99 once**: rest of both campaigns, Free Play, editor.
- Feedback marks: teal circle = exact, orange triangle = wrong place, black cross = not in the code. Never say green / red.
- Lie Mode: exactly one fake feedback per round. The winning guess is always true.
- No ads. No account. In-app language switcher.

Name max 30. **Name is `Mind Cipher` in all 12 locales** (space, no translation). Subtitle max 30. Keywords max 100, comma-separated, no spaces around commas. Do not repeat words already in the name (`mind`, `cipher`) or the subtitle. Category keywords sit in the subtitle (`Mastermind` / `珠玑妙算` / `ヒットアンドブロー`) because iOS weights subtitle above the keyword field.

Apple Search Ads starter list is in `docs/aso_1.1.json` → `search_ads`. Exact: mastermind, code breaker, 珠玑妙算, ヒットアンドブロー. Negative exact: mastermind.com, wordle, sudoku, cryptogram.

---

## English (U.S.) `en-US`

**Name:** Mind Cipher

**Subtitle:** Mastermind. One clue lies

**Keywords:** code,breaker,logic,puzzle,brain,teaser,daily,deduction,color,secret,offline,crack,riddle,duel

**Promotional Text:**
```
Mastermind with a liar. 480 levels, daily, duel. $2.99 once. No ads.
```

**Description:**
```
Mind Cipher is a Mastermind-style code-breaking puzzle. Guess the hidden color code. Each guess comes back as exact, wrong place, or out — teal circle, orange triangle, black cross.

Then try Lie Mode. Exactly one feedback in the round is fake. The rest are true. Cross-check the reports, find the contradiction, and crack the code anyway.

Classic Missions teach the real marks, 240 levels from beginner to master. Lie Missions run a matching 240 where one clue always lies. Daily Challenge is a new puzzle every day. Duel Mode is pass-and-play: one sets the code, the other breaks it.

Smart notes sit on the board so you can mark eliminated and confirmed colors. Hints can be earned by playing. No ads. No account.

Free to start: Daily, Duel, Classic 1–40, and Lie 1–80. Pro is a one-time $2.99 unlock for the rest of both campaigns, Free Play, and the custom editor.

The app follows your language, or you can set it in Settings: English, 简体中文, 繁體中文, 日本語, 한국어, Español, العربية, Deutsch, Français, עברית, Português, Türkçe.
```

**What’s New:**
```
The app now speaks twelve languages, including Arabic and Hebrew, and you can switch language in Settings without leaving the game.

The puzzle board stays left-to-right so pegs, notes, and slots do not flip. Difficulty names and achievements are translated. Levels that allow repeats are labeled, so Easy and Medium no longer look the same.

Copy now matches the game: 240 Classic and 240 Lie missions.
```

---

## 简体中文 `zh-Hans`

**Name:** Mind Cipher

**Subtitle:** 珠玑妙算·一条线索是假的

**Keywords:** 密码,破译,逻辑,益智,推理,每日挑战,谎言,大师头脑,猜颜色,烧脑,解谜,单机,桌游,解码,神机妙算,颜色密码,无广告,双人,猜密码,头脑训练

**Promotional Text:**
```
珠玑妙算，一条线索是假的。480 关、每日、双人。一次 $2.99。无广告。
```

**Description:**
```
Mind Cipher 是珠玑妙算（Mastermind）类的颜色密码推理游戏。每次猜测会得到三种反馈：青绿圆表示颜色和位置都对，橙三角表示颜色对但位置错，黑叉表示这个颜色不在密码里。

谎言模式里，一局里恰好有一条反馈是假的，其余都是真的。交叉验证，找出矛盾，照样破译。

经典任务 240 关，从入门到大师，先学会真实反馈。谎言任务另有 240 关，每关都有一条假线索。每日挑战每天一题。双人对战一人设密码、一人来破译。

棋盘上有智能笔记，用来标记排除和确认的颜色。提示币可以靠游玩获得。没有广告，不用注册。

免费内容：每日挑战、双人对战、经典 1–40 关、谎言 1–80 关。Pro 一次买断 $2.99，解锁两个战役的剩余关卡、自由模式和关卡编辑器。

应用会跟随系统语言，也可以在设置里切换：简体中文、繁體中文、English、日本語、한국어、Español、العربية、Deutsch、Français、עברית、Português、Türkçe。
```

**What’s New:**
```
支持 12 种语言，含阿拉伯语和希伯来语，可在设置里直接切换。

棋盘保持从左到右，色钉、笔记和槽位不会跟着镜像。难度名和成就已翻译。允许重复颜色的难度会标出来，简单和中等不再长得一样。

商店文案与游戏一致：经典和谎言各 240 关。
```

---

## 繁體中文 `zh-Hant`

**Name:** Mind Cipher

**Subtitle:** 珠璣妙算·一條線索是假的

**Keywords:** 密碼,破譯,邏輯,益智,推理,每日挑戰,謊言,猜顏色,燒腦,解謎,單機,桌遊,解碼,神機妙算,顏色密碼,無廣告,雙人,猜密碼,頭腦訓練

**Promotional Text:**
```
珠璣妙算，一條線索是假的。480 關、每日、雙人。一次 $2.99。無廣告。
```

**Description:**
```
Mind Cipher 是珠璣妙算（Mastermind）類的顏色密碼推理遊戲。每次猜測會得到三種回饋：青綠圓表示顏色和位置都對，橙三角表示顏色對但位置錯，黑叉表示這個顏色不在密碼裡。

謊言模式裡，一局恰好有一條回饋是假的，其餘都是真的。交叉驗證，找出矛盾，照樣破譯。

經典任務 240 關，從入門到大師，先學會真實回饋。謊言任務另有 240 關，每關都有一條假線索。每日挑戰每天一題。雙人對戰一人設密碼、一人來破譯。

棋盤上有智慧筆記，用來標記排除和確認的顏色。提示幣可以靠遊玩獲得。沒有廣告，不用註冊。

免費內容：每日挑戰、雙人對戰、經典 1–40 關、謊言 1–80 關。Pro 一次買斷 $2.99，解鎖兩個戰役的剩餘關卡、自由模式和關卡編輯器。

應用會跟隨系統語言，也可以在設定裡切換。
```

**What’s New:**
```
支援 12 種語言，含阿拉伯文與希伯來文，可在設定裡直接切換。

棋盤保持由左到右，色釘、筆記和槽位不會跟著鏡像。難度名稱和成就已翻譯。允許重複顏色的難度會標出來，簡單和中等不再長得一樣。

商店文案與遊戲一致：經典和謊言各 240 關。
```

---

## 日本語 `ja`

**Name:** Mind Cipher

**Subtitle:** ヒットアンドブロー、1つは嘘

**Keywords:** マスターマインド,暗号,論理,パズル,推理,デイリー,色当て,頭脳,暗号解読,オフライン,対戦,脳トレ,ボードゲーム

**Promotional Text:**
```
ヒットアンドブローに嘘が1つ。480レベル、デイリー、対戦。買い切り$2.99。広告なし。
```

**Description:**
```
Mind Cipher はヒットアンドブロー／マスターマインド型の色暗号パズルです。各予想には3種類の手がかりが返ります。青緑の丸は色も位置も正しい、オレンジの三角は色は正しいが位置が違う、黒いバツはその色が暗号にない、という意味です。

嘘モードでは、1ラウンドにつき手がかりの嘘はちょうど1つ。残りは本当です。突き合わせて矛盾を見つけ、それでも解読してください。

クラシック任務は240レベル。嘘の任務も240レベルで、各ラウンドに嘘の手がかりが1つあります。デイリーは毎日新しい問題。対戦は一人が暗号を決め、もう一人が解読します。

盤面のメモで除外と確定を残せます。ヒントはプレイで貯められます。広告なし。アカウント不要。

無料はデイリー、対戦、クラシック1–40、嘘1–80。Proは一度きりの$2.99で、残りのキャンペーン、フリープレイ、編集を解除します。
```

**What’s New:**
```
12言語に対応。アラビア語とヘブライ語を含み、設定から切り替えられます。

盤面は左から右のままです。難易度名と実績を翻訳しました。色の重複が許される難易度には印が付きます。
```

---

## 한국어 `ko`

**Name:** Mind Cipher

**Subtitle:** 마스터마인드·하나가 거짓

**Keywords:** 암호,논리,퍼즐,추론,일일도전,거짓말,색맞추기,두뇌,오프라인,보드,두뇌훈련,보드게임

**Promotional Text:**
```
마스터마인드, 단서 하나가 가짜. 480레벨, 일일, 대전. $2.99 한 번. 광고 없음.
```

**Description:**
```
Mind Cipher는 마스터마인드 스타일의 숨겨진 색 암호 퍼즐입니다. 각 추측은 세 가지 단서를 돌려줍니다. 청록 원은 색과 위치가 모두 맞고, 주황 삼각형은 색만 맞고, 검은 엑스는 암호에 없는 색입니다.

거짓말 모드에서는 라운드마다 가짜 단서가 정확히 하나이고 나머지는 참입니다. 교차 확인해서 모순을 찾고, 그래도 암호를 깨세요.

클래식 임무 240개, 거짓말 임무 240개. 일일 도전은 매일 새 퍼즐입니다. 대전은 한 명이 암호를 정하고 한 명이 풉니다.

보드 위의 노트로 제외와 확정을 표시할 수 있습니다. 힌트는 플레이로 모을 수 있습니다. 광고 없음. 계정 불필요.

무료: 일일, 대전, 클래식 1–40, 거짓말 1–80. Pro는 $2.99 한 번으로 나머지 캠페인, 자유 플레이, 편집기를 엽니다.
```

**What’s New:**
```
12개 언어를 지원하며 설정에서 바꿀 수 있습니다. 아랍어와 히브리어 포함.

보드는 왼쪽에서 오른쪽으로 유지됩니다. 난이도 이름과 업적이 번역되었습니다. 색 반복이 허용되는 난이도는 표시됩니다.
```

---

## Español `es-ES`

**Name:** Mind Cipher

**Subtitle:** Mastermind: una pista miente

**Keywords:** rompe,codigos,logica,puzzle,deduccion,reto,diario,colores,estrategia,offline,cerebro

**Promotional Text:**
```
Mastermind con un mentiroso. 480 niveles, diario, duelo. 2,99 $ una vez. Sin anuncios.
```

**Description:**
```
Mind Cipher es un Mastermind: un puzzle de descifrar un código de colores. Cada intento devuelve tres marcas: círculo teal = color y sitio correctos, triángulo naranja = color bien y sitio mal, cruz negra = ese color no está.

En Modo Mentira, exactamente una pista de la ronda es falsa. El resto son verdad. Cruza los informes, encuentra la contradicción y descifra el código igual.

Misiones clásicas: 240 niveles. Misiones Mentira: otras 240, con una pista falsa en cada ronda. El desafío diario es un puzzle nuevo cada día. El duelo es pasar el teléfono: uno pone el código, el otro lo rompe.

Las notas van sobre el tablero. Las pistas se ganan jugando. Sin anuncios. Sin cuenta.

Gratis: diario, duelo, clásico 1–40 y Mentira 1–80. Pro es 2,99 $ una vez: el resto de ambas campañas, juego libre y el editor.
```

**What’s New:**
```
La app habla doce idiomas, árabe y hebreo incluidos, y puedes cambiar el idioma en Ajustes.

El tablero sigue de izquierda a derecha. Nombres de dificultad y logros están traducidos. Las dificultades que permiten repeticiones van marcadas.
```

---

## العربية `ar-SA`

**Name:** Mind Cipher

**Subtitle:** ماسترميند: دليل يكذب

**Keywords:** فك,الشفرة,منطق,لغز,استدلال,تحدي,يومي,ألوان,استراتيجية,أوفلاين

**Promotional Text:**
```
ماسترميند ودليل كاذب. 480 مستوى، يومي، مبارزة. 2.99$ مرة واحدة. بلا إعلانات.
```

**Description:**
```
Mind Cipher لعبة ماسترميند لفك رمز ألوان. كل تخمين يعيد ثلاث علامات: دائرة فيروزية = اللون والمكان صحيحان، مثلث برتقالي = اللون صحيح والمكان خطأ، علامة سوداء = اللون ليس في الرمز.

في وضع الكذب، دليل واحد بالضبط في الجولة مزيف والباقي صادق. قارن التقارير، ابحث عن التناقض، وافك الرمز رغم ذلك.

المهام الكلاسيكية: 240 مستوى. مهام الكذب: 240 أخرى، وفي كل جولة دليل كاذب واحد. التحدي اليومي لغز جديد كل يوم. المبارزة تمرير للهاتف: واحد يضع الرمز والآخر يفكه.

الملاحظات على اللوحة. التلميحات تُكسب باللعب. بلا إعلانات. بلا حساب.

مجاناً: اليومي، المبارزة، الكلاسيكي 1–40، والكذب 1–80. Pro شراء لمرة واحدة بـ 2.99$ لبقية الحملتين واللعب الحر والمحرر.
```

**What’s New:**
```
التطبيق يتحدث اثنتي عشرة لغة، منها العربية والعبرية، ويمكن تغيير اللغة من الإعدادات.

لوحة اللعب تبقى من اليسار إلى اليمين. أسماء الصعوبة والإنجازات مترجمة. الصعوبات التي تسمح بتكرار الألوان معلّمة.
```

---

## Deutsch `de-DE`

**Name:** Mind Cipher

**Subtitle:** Mastermind: ein Hinweis lügt

**Keywords:** code,knacken,logik,puzzle,taglich,farben,strategie,offline,gehirn,brett,raetsel,duell

**Promotional Text:**
```
Mastermind mit einem Lügner. 480 Level, täglich, Duell. 2,99 $ einmal. Keine Werbung.
```

**Description:**
```
Mind Cipher ist Mastermind: ein Puzzle zum Knacken eines Farbcodes. Jeder Tipp gibt drei Marken: Türkis-Kreis = Farbe und Platz richtig, oranges Dreieck = Farbe richtig und Platz falsch, schwarzes Kreuz = die Farbe ist nicht im Code.

Im Lügenmodus ist genau ein Hinweis der Runde falsch. Der Rest stimmt. Gleiche die Berichte ab, finde den Widerspruch und knacke den Code trotzdem.

Klassik-Missionen: 240 Level. Lügen-Missionen: weitere 240, mit einem falschen Hinweis pro Runde. Die tägliche Challenge ist jeden Tag neu. Duellmodus: einer legt den Code, einer knackt ihn.

Notizen liegen auf dem Brett. Tipps verdienst du durch Spielen. Keine Werbung. Kein Konto.

Kostenlos: täglich, Duell, Klassik 1–40 und Lüge 1–80. Pro ist 2,99 $ einmal: Rest beider Kampagnen, Freies Spiel und Editor.
```

**What’s New:**
```
Die App spricht zwölf Sprachen, auch Arabisch und Hebräisch, umschaltbar in den Einstellungen.

Das Spielfeld bleibt von links nach rechts. Schwierigkeitsnamen und Erfolge sind übersetzt. Stufen mit erlaubten Wiederholungen sind gekennzeichnet.
```

Note: German keywords omit umlauts (`taglich`, `raetsel`) so they still match typed search. `Mastermind` lives in the subtitle, not the keyword field.

---

## Français `fr-FR`

**Name:** Mind Cipher

**Subtitle:** Mastermind : un indice ment

**Keywords:** casse,code,logique,puzzle,deduction,defi,quotidien,couleurs,offline,cerveau

**Promotional Text:**
```
Mastermind avec un menteur. 480 niveaux, quotidien, duel. 2,99 $ une fois. Sans pub.
```

**Description:**
```
Mind Cipher est un Mastermind : un puzzle pour casser un code couleur. Chaque essai renvoie trois marques : cercle teal = bonne couleur au bon endroit, triangle orange = bonne couleur au mauvais endroit, croix noire = cette couleur n’est pas dans le code.

En Mode Mensonge, exactement un indice de la manche est faux. Le reste est vrai. Recoupe les rapports, trouve la contradiction, et casse le code quand même.

Missions classiques : 240 niveaux. Missions Mensonge : 240 autres, avec un indice faux par manche. Le défi du jour est nouveau chaque jour. Le duel se joue à deux : l’un pose le code, l’autre le casse.

Les notes sont sur le plateau. Les indices s’obtiennent en jouant. Sans pub. Sans compte.

Gratuit : quotidien, duel, classique 1–40 et Mensonge 1–80. Pro coûte 2,99 $ une fois : le reste des deux campagnes, la partie libre et l’éditeur.
```

**What’s New:**
```
L’app parle douze langues, arabe et hébreu compris, et se change dans Réglages.

Le plateau reste de gauche à droite. Noms de difficulté et succès sont traduits. Les difficultés qui autorisent les doublons sont marquées.
```

---

## עברית `he`

**Name:** Mind Cipher

**Subtitle:** מאסטרמיינד: רמז אחד משקר

**Keywords:** פיצוח,קוד,לוגיקה,חידה,היסק,אתגר,יומי,צבעים,אסטרטגיה,אופליין

**Promotional Text:**
```
מאסטרמיינד עם שקרן. 480 שלבים, יומי, דו-קרב. 2.99$ חד-פעמי. בלי פרסומות.
```

**Description:**
```
Mind Cipher היא מאסטרמיינד: חידת פיצוח קוד צבעים. כל ניחוש מחזיר שלושה סימנים: עיגול טורקיז = צבע ומיקום נכונים, משולש כתום = צבע נכון ומיקום שגוי, איקס שחור = הצבע לא בקוד.

במצב שקר, בדיוק רמז אחד בסיבוב מזויף והשאר אמיתיים. הצליבו דיווחים, מצאו את הסתירה, ופצחו את הקוד בכל זאת.

משימות קלאסיות: 240 שלבים. משימות שקר: עוד 240, עם רמז מזויף אחד בכל סיבוב. האתגר היומי הוא חידה חדשה כל יום. דו-קרב: אחד קובע קוד, השני מפצח.

הפתקים על הלוח. רמזים נצברים במשחק. בלי פרסומות. בלי חשבון.

חינם: יומי, דו-קרב, קלאסי 1–40 ושקר 1–80. Pro הוא 2.99$ חד-פעמי: שאר שתי העלילות, משחק חופשי והעורך.
```

**What’s New:**
```
האפליקציה מדברת שתים-עשרה שפות, כולל ערבית ועברית, וניתן להחליף שפה בהגדרות.

לוח המשחק נשאר משמאל לימין. שמות קושי והישגים מתורגמים. רמות שמאפשרות כפילויות מסומנות.
```

---

## Português (Brasil) `pt-BR`

**Name:** Mind Cipher

**Subtitle:** Mastermind: uma pista mente

**Keywords:** quebra,codigo,logica,puzzle,deducao,desafio,diario,cores,offline,cerebro

**Promotional Text:**
```
Mastermind com um mentiroso. 480 níveis, diário, duelo. US$ 2,99 uma vez. Sem anúncios.
```

**Description:**
```
Mind Cipher é um Mastermind: um puzzle para decifrar um código de cores. Cada palpite devolve três marcas: círculo teal = cor e lugar certos, triângulo laranja = cor certa e lugar errado, cruz preta = essa cor não está no código.

No Modo Mentira, exatamente uma pista da rodada é falsa. O resto é verdade. Cruze os relatórios, ache a contradição e decifre o código mesmo assim.

Missões clássicas: 240 níveis. Missões Mentira: outras 240, com uma pista falsa por rodada. O desafio diário é um puzzle novo todo dia. O duelo é passar o telefone: um define o código, o outro decifra.

As notas ficam no tabuleiro. Dicas se ganham jogando. Sem anúncios. Sem conta.

Grátis: diário, duelo, clássico 1–40 e Mentira 1–80. Pro é US$ 2,99 uma vez: o resto das duas campanhas, jogo livre e o editor.
```

**What’s New:**
```
O app fala doze idiomas, incluindo árabe e hebraico, e dá para trocar em Ajustes.

O tabuleiro continua da esquerda para a direita. Nomes de dificuldade e conquistas estão traduzidos. Dificuldades que permitem repetição vêm marcadas.
```

---

## Türkçe `tr`

**Name:** Mind Cipher

**Subtitle:** Mastermind: bir ipucu yalan

**Keywords:** kod,kirma,mantik,bulmaca,cikarsama,gunluk,renk,strateji,offline,zeka

**Promotional Text:**
```
Mastermind, bir yalancı. 480 seviye, günlük, düello. Tek sefer 2,99 $. Reklam yok.
```

**Description:**
```
Mind Cipher bir Mastermind oyunu: gizli bir renk kodunu kırma bulmacasıdır. Her tahmin üç işaret döner: turkuaz daire = renk ve yer doğru, turuncu üçgen = renk doğru yer yanlış, siyah çarpı = bu renk kodda yok.

Yalan modunda tur başına tam bir ipucu sahtedir. Gerisi doğrudur. Raporları çaprazla, çelişkiyi bul, kodu yine kır.

Klasik görevler: 240 seviye. Yalan görevleri: 240 daha, her turda bir sahte ipucu. Günlük görev her gün yeni. Düello: biri kodu koyar, diğeri çözer.

Notlar tahtada durur. İpuçları oynayarak birikir. Reklam yok. Hesap yok.

Ücretsiz: günlük, düello, klasik 1–40 ve yalan 1–80. Pro tek sefer 2,99 $: iki kampanyanın gerisi, serbest oyun ve editör.
```

**What’s New:**
```
Uygulama on iki dil konuşuyor, Arapça ve İbranice dahil; dil Ayarlar’dan değişir.

Tahta soldan sağa kalır. Zorluk adları ve başarımlar çevrildi. Renk tekrarına izin veren zorluklar işaretli.
```

---

## IAP display names

Keep product IDs. Localize the name (30) and description (45) in each locale you added.

| Product ID | EN name | EN description |
|---|---|---|
| `com.codebreaker.app.pro` | Pro Unlock | Rest of Lie & Classic, Free Play, editor |
| `com.codebreaker.app.hints5` | 5 Hint Coins | A small pack of hints |
| `com.codebreaker.app.hints15` | 15 Hint Coins | Best value for casual play |
| `com.codebreaker.app.hints50` | 50 Hint Coins | A large pack of hints |

| Locale | Pro | 5 / 15 / 50 coins |
|---|---|---|
| zh-Hans | 解锁 Pro | 5 / 15 / 50 枚提示币 |
| zh-Hant | 解鎖 Pro | 5 / 15 / 50 枚提示幣 |
| ja | Proを解除 | ヒントコイン 5 / 15 / 50 |
| ko | Pro 해제 | 힌트 코인 5 / 15 / 50 |
| es-ES | Desbloquear Pro | 5 / 15 / 50 monedas de pista |
| ar-SA | فتح Pro | 5 / 15 / 50 عملة تلميح |
| de-DE | Pro freischalten | 5 / 15 / 50 Tipp-Münzen |
| fr-FR | Débloquer Pro | 5 / 15 / 50 pièces d’indice |
| he | פתח Pro | 5 / 15 / 50 מטבעות רמז |
| pt-BR | Desbloquear Pro | 5 / 15 / 50 moedas de dica |
| tr | Pro’yu aç | 5 / 15 / 50 ipucu jetonu |

---

## Review notes (English)

```
Mind Cipher is a single-player and pass-and-play Mastermind-style puzzle.

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
```
