import Foundation

private let currentLanguage: String = "en"

private let strings: [String: [String: String]] = [
    // 主页
    "app.title":        ["zh": "Mind Cipher",       "en": "Mind Cipher"],
    "app.subtitle":     ["zh": "MIND CIPHER",      "en": "MIND CIPHER"],
    "menu.daily":       ["zh": "每日挑战",         "en": "Daily Challenge"],
    "menu.daily.done":  ["zh": "今日已完成 ✓",     "en": "Done today ✓"],
    "menu.daily.todo":  ["zh": "今日尚未挑战",     "en": "Not yet today"],
    "menu.classic":     ["zh": "经典任务",         "en": "Classic Missions"],
    "menu.classic.sub": ["zh": "240个关卡 · 逐步解锁", "en": "240 levels · Unlock progressively"],
    "menu.lie":         ["zh": "谎言任务",         "en": "Lie Missions"],
    "menu.lie.sub":     ["zh": "前80关免费 · 含1次虚假反馈", "en": "80 free · 1 fake feedback"],
    "menu.free":        ["zh": "自由模式",         "en": "Free Play"],
    "menu.free.sub":    ["zh": "自定义难度 · 无限挑战", "en": "Custom difficulty · Endless"],
    "menu.duel":        ["zh": "双人对战",         "en": "Duel Mode"],
    "menu.duel.sub":    ["zh": "一人设密码 · 一人来破译", "en": "One sets · One cracks"],
    "menu.editor":      ["zh": "自定义关卡",       "en": "Custom Level"],
    "menu.editor.sub":  ["zh": "调整所有参数 · 创造挑战", "en": "All params · Create challenge"],
    "menu.more":        ["zh": "更多",             "en": "More"],
    "menu.classic.short":["zh": "240 关逐步解锁",   "en": "240 levels"],
    "menu.lie.short":   ["zh": "一条线索是假的",     "en": "One clue is fake"],
    "menu.achievements":["zh": "成就",             "en": "Achievements"],
    "menu.feedback":     ["zh": "发送反馈",         "en": "Send Feedback"],
    "menu.feedback.sub": ["zh": "认真反馈可送 Pro", "en": "Useful feedback may unlock Pro"],
    "home.feedback.tip":  ["zh": "有用的反馈可送 Pro", "en": "Useful feedback can unlock Pro"],

    // 统计
    "stats.games":      ["zh": "总局数", "en": "Games"],
    "stats.winrate":    ["zh": "胜率",   "en": "Win%"],
    "stats.streak":     ["zh": "连胜",   "en": "Streak"],
    "stats.stars":      ["zh": "星数",   "en": "Stars"],
    "stats.best":       ["zh": "最佳",   "en": "Best"],

    // 游戏
    "game.free":        ["zh": "自由模式",   "en": "Free Play"],
    "game.duel":        ["zh": "双人对战",   "en": "Duel Mode"],
    "game.attempts":    ["zh": "次",         "en": "left"],
    "game.hint":        ["zh": "提示",       "en": "Hint"],
    "game.submit":      ["zh": "提交",       "en": "Submit"],

    // 参数
    "param.length":     ["zh": "密码长度", "en": "Code length"],
    "param.colors":     ["zh": "可用颜色", "en": "Colors"],
    "param.attempts":   ["zh": "最大尝试", "en": "Max attempts"],
    "param.repeat":     ["zh": "允许重复", "en": "Allow repeats"],
    "param.timelimit":  ["zh": "时间限制", "en": "Time limit"],
    "param.yes":        ["zh": "是",       "en": "Yes"],
    "param.no":         ["zh": "否",       "en": "No"],

    // 结果
    "result.win":       ["zh": "密码破译成功！",               "en": "Code Cracked!"],
    "result.win.steps": ["zh": "用了 %d 步完成破译",           "en": "Solved in %d steps"],
    "result.lose":      ["zh": "破译失败",                     "en": "Failed"],
    "result.lose.desc": ["zh": "密码未能在限定次数内破解",     "en": "Code not cracked within the limit"],
    "result.code":      ["zh": "密码：",                       "en": "Code:"],
    "result.retry":     ["zh": "重新挑战",                     "en": "Retry"],
    "result.next":      ["zh": "下一关 →",                     "en": "Next →"],
    "result.again":     ["zh": "再来一局",                     "en": "Play Again"],
    "result.share":     ["zh": "分享",                         "en": "Share"],
    "result.back":      ["zh": "返回",                         "en": "Back"],

    // 谎言
    "lie.mode":         ["zh": "谎言模式",                     "en": "Lie Mode"],
    "lie.warning":      ["zh": "谎言模式",                 "en": "Lie Mode"],
    "lie.task":         ["zh": "谎言任务",                     "en": "Lie Missions"],
    "lie.banner":       ["zh": "每关含1次虚假反馈",            "en": "1 fake feedback per level"],
    "lie.reveal":       ["zh": "第 %d 步是谎言！",             "en": "Step %d was a lie!"],
    "lie.fake":         ["zh": "当时显示",                      "en": "Shown"],
    "lie.real":         ["zh": "→ 实际是",                      "en": "→ Truth"],
    "lie.real.short":   ["zh": "实际是",                        "en": "Truth"],
    "lie.feedback":     ["zh": "%d精确 %d位置",                "en": "%d exact %d partial"],
    "lie.notrigger":    ["zh": "本局谎言未触发（你赢得太快了！）", "en": "No lie triggered (you won too fast!)"],
    "lie.start":        ["zh": "开始谎言挑战",                 "en": "Start Lie Challenge"],
    "lie.toggle":       ["zh": "谎言模式",                     "en": "Lie Mode"],
    "lie.toggle.desc":  ["zh": "含1次虚假反馈",                "en": "Includes 1 fake feedback"],
    "lie.kickoff":      ["zh": "这一局里，有一条线索会说谎",      "en": "One of these clues will lie"],
    "lie.clue":         ["zh": "其中一条线索是假的",            "en": "One of these clues is false"],
    "lie.stamp":        ["zh": "谎",                          "en": "LIE"],

    // 关卡
    "level.title":      ["zh": "关卡 %d",     "en": "Level %d"],
    "level.tier1":      ["zh": "初级特工",     "en": "Junior Agent"],
    "level.tier2":      ["zh": "中级特工",     "en": "Agent"],
    "level.tier3":      ["zh": "高级特工",     "en": "Senior Agent"],
    "level.tier4":      ["zh": "精英特工",     "en": "Elite Agent"],
    "level.tier5":      ["zh": "首席特工",     "en": "Chief Agent"],
    "level.tier6":      ["zh": "传奇特工",     "en": "Legend Agent"],

    // 教程
    "tutorial.next":    ["zh": "下一步",       "en": "Next"],
    "tutorial.start":   ["zh": "开始破译！",   "en": "Start Cracking!"],
    "tutorial.t1":      ["zh": "破译隐藏密码", "en": "Crack the Code"],
    "tutorial.t2":      ["zh": "选择颜色填入", "en": "Pick Colors"],
    "tutorial.t3":      ["zh": "解读反馈线索", "en": "Read the Clues"],
    "tutorial.t4":      ["zh": "善用提示",     "en": "Use Hints"],
    "tutorial.d1":      ["zh": "系统生成了一组隐藏的颜色密码\n你需要在有限次数内猜出正确组合",
                          "en": "A secret color code is hidden\nGuess it within limited attempts"],
    "tutorial.d2":      ["zh": "点击底部颜色球放入猜测槽位\n填满所有位置后点击提交",
                          "en": "Tap colors to fill slots\nSubmit when all slots are filled"],
    "tutorial.d3":      ["zh": "🟢 绿色 = 颜色和位置都对\n🟠 橙色 = 颜色对但位置不对\n⚪ 空圈 = 该颜色不在密码中",
                          "en": "🟢 Green = Right color, right spot\n🟠 Orange = Right color, wrong spot\n⚪ Empty = Not in code"],
    "tutorial.d4":      ["zh": "每局有一次提示机会\n会告诉你某个位置的正确颜色",
                          "en": "One hint per game\nReveals the color at a position"],

    // 双人
    "duel.title":       ["zh": "双人对战",           "en": "Duel Mode"],
    "duel.desc":        ["zh": "一人设密码，一人来破译", "en": "One sets code, one cracks it"],
    "duel.p1.setup":    ["zh": "玩家 1 设置密码",    "en": "Player 1: Set Code"],
    "duel.p2.start":    ["zh": "玩家 2 开始破译",    "en": "Player 2: Start"],
    "duel.confirm":     ["zh": "密码已设好 →",       "en": "Code Set →"],
    "duel.handoff":     ["zh": "请将手机交给对手",   "en": "Pass to Opponent"],
    "duel.handoff.desc":["zh": "密码已锁定，请勿偷看！", "en": "Code locked. No peeking!"],
    "duel.rules":       ["zh": "对战规则",           "en": "Rules"],

    // 设置
    "settings.title":   ["zh": "设置",     "en": "Settings"],
    "settings.sound":   ["zh": "音效",     "en": "Sound"],
    "settings.haptics": ["zh": "触觉反馈", "en": "Haptics"],
    "settings.colorblind": ["zh": "色盲辅助", "en": "Colorblind"],
    "feedback.section":    ["zh": "支持",                 "en": "Support"],
    "feedback.row":        ["zh": "发送反馈",             "en": "Send Feedback"],
    "feedback.title":     ["zh": "反馈",                 "en": "Feedback"],
    "feedback.lead":       ["zh": "Bug、卡点和点子都欢迎。没有 GitHub 账号可以用 Google 或 Apple 登录。",
                            "en": "Bugs, rough edges, and ideas all help. You can sign in to GitHub with Google or Apple."],
    "feedback.pro":       ["zh": "具体、能动手改的反馈，我们看过之后可能会私下赠送 Pro 兑换码。兑换码不会发在公开 Issue 里。App Store 评分不参与、也没有奖励。",
                            "en": "Specific, useful feedback may receive a Pro offer code after we review it. Codes are sent privately — never on the public issue. App Store ratings are not required and are not rewarded."],
    "feedback.public":    ["zh": "GitHub Issue 是公开的，不要写不想公开的信息。",
                            "en": "GitHub issues are public. Don't include anything you want to keep private."],
    "feedback.github":     ["zh": "打开 GitHub Issue",     "en": "Open GitHub Issue"],
    "feedback.github.sub": ["zh": "在浏览器中打开，可用 Google / Apple 登录",
                            "en": "Opens GitHub in the browser"],
    "feedback.email":     ["zh": "改用邮件",             "en": "Email instead"],
    "feedback.email.sub":  ["zh": "sirouni@msn.com", "en": "sirouni@msn.com"],

    // 颜色
    "color.red":    ["zh": "红", "en": "Red"],
    "color.green":  ["zh": "绿", "en": "Green"],
    "color.blue":   ["zh": "蓝", "en": "Blue"],
    "color.yellow": ["zh": "黄", "en": "Yellow"],
    "color.purple": ["zh": "紫", "en": "Purple"],
    "color.orange": ["zh": "橙", "en": "Orange"],
    "color.cyan":   ["zh": "青", "en": "Cyan"],
    "color.pink":   ["zh": "粉", "en": "Pink"],

    // 每日
    "daily.title":      ["zh": "每日挑战",           "en": "Daily Challenge"],
    "daily.completed":  ["zh": "今日挑战已完成",     "en": "Today's challenge complete"],
    "daily.tomorrow":   ["zh": "明天再来挑战新密码！", "en": "Come back tomorrow!"],
    "daily.start":      ["zh": "开始挑战",           "en": "Start"],
    "daily.back":       ["zh": "返回首页",           "en": "Back to Home"],

    // 编辑器
    "editor.title":     ["zh": "自定义关卡", "en": "Custom Level"],
    "editor.start":     ["zh": "开始自定义挑战", "en": "Start Custom Challenge"],

    // 在线对战
    "menu.online":      ["zh": "在线对战",                 "en": "Online Match"],
    "menu.online.sub":  ["zh": "Game Center 实时竞速",     "en": "Game Center speed duel"],
    "online.title":     ["zh": "在线对战",                 "en": "Online Match"],
    "online.desc":      ["zh": "与全球玩家实时竞速破译",   "en": "Race against players worldwide"],
    "online.find":      ["zh": "寻找对手",                 "en": "Find Match"],
    "online.searching": ["zh": "正在匹配对手…",            "en": "Searching for opponent…"],
    "online.waiting":   ["zh": "等待对手就绪…",            "en": "Waiting for opponent…"],
    "online.gc.required":["zh": "请先登录 Game Center",    "en": "Sign in to Game Center first"],
    "online.disconnected":["zh": "%@ 已断开连接",          "en": "%@ disconnected"],
    "online.rules.title":["zh": "对战规则",                "en": "Rules"],
    "online.rule1":     ["zh": "1. 匹配成功后双方破解同一密码", "en": "1. Both players crack the same code"],
    "online.rule2":     ["zh": "2. 先破解者获胜",          "en": "2. First to solve wins"],
    "online.rule3":     ["zh": "3. 步数相同则用时短者胜",  "en": "3. Fewer steps wins; ties broken by time"],
    "online.steps":     ["zh": "步",                       "en": "steps"],
    "online.rematch":   ["zh": "再来一局",                 "en": "Rematch"],
    "online.exit":      ["zh": "退出对战",                 "en": "Exit Match"],
    "online.timeout":   ["zh": "连接超时，请重新匹配",     "en": "Connection timed out. Please try again"],
    "online.opponent.left":["zh": "对手已离开",            "en": "Opponent left"],
    "online.you.win":   ["zh": "你赢了！",                 "en": "You Win!"],
    "online.you.lose":  ["zh": "你输了",                   "en": "You Lose"],
    "online.draw":      ["zh": "平局",                     "en": "Draw"],

    // 付费
    "paywall.unlock":       ["zh": "解锁 Pro",                         "en": "Unlock Pro"],
    "paywall.restore":      ["zh": "恢复购买",                         "en": "Restore Purchases"],
    "paywall.price":        ["zh": "一次买断",                         "en": "One-time unlock"],
    "paywall.benefit.lie":  ["zh": "谎言任务后半段：交叉验证假线索",     "en": "The rest of Lie Missions — cross-check the fake clue"],
    "paywall.benefit.classic":["zh": "经典任务剩余关卡",                 "en": "Remaining Classic Missions"],
    "paywall.benefit.free": ["zh": "自由模式（可开谎言）",               "en": "Free Play, including Lie Mode"],
    "paywall.benefit.editor":["zh": "自定义关卡编辑器",                  "en": "Custom Level Editor"],
    "paywall.classic.title":["zh": "继续深入",                         "en": "Go deeper"],
    "paywall.classic.sub":  ["zh": "解锁经典 41–240 关、完整谎言战役、自由模式和编辑器。", "en": "Unlock Classic 41–240, the full Lie campaign, Free Play, and the editor."],
    "paywall.lie.title":    ["zh": "继续识破谎言",                     "en": "Keep hunting lies"],
    "paywall.lie.sub":      ["zh": "后面的关需要真正交叉验证。解锁谎言 81–240 关和全部内容。", "en": "The next missions need real cross-checks. Unlock Lie 81–240 and the rest of the game."],
    "paywall.free.title":   ["zh": "自由模式需要 Pro",                 "en": "Free Play is Pro"],
    "paywall.free.sub":     ["zh": "自选难度，也可打开谎言，不走战役格子。", "en": "Pick any difficulty — including Lie — and play without the campaign grid."],
    "paywall.editor.title": ["zh": "关卡编辑器需要 Pro",               "en": "Editor is Pro"],
    "paywall.editor.sub":   ["zh": "自己做题、分享给朋友。",             "en": "Build puzzles and share them with a friend."],
    "paywall.done.classic.title":["zh": "初级特工毕业",                 "en": "Junior Agent complete"],
    "paywall.done.classic.sub":["zh": "规则你已经会了。解锁后面的经典关，以及更深的谎言任务。", "en": "You've got the rules. Unlock the rest of Classic and the deeper Lie campaign."],
    "paywall.done.lie.title":["zh": "你已经能识破谎言",                 "en": "You can spot a lie"],
    "paywall.done.lie.sub": ["zh": "后面要交叉验证线索。$2.99 解锁剩余谎言关和全部内容。", "en": "Now the clues need cross-checking. Unlock the rest of Lie Mode and the full game."],
    "store.pro.blurb":      ["zh": "更深的谎言任务、剩余战役、自由模式和编辑器", "en": "Deeper Lie missions, remaining campaign, Free Play & editor"],
    "store.pro.done":       ["zh": "Pro 已解锁",                       "en": "Pro unlocked"],
]

func L(_ key: String) -> String {
    strings[key]?[currentLanguage] ?? strings[key]?["zh"] ?? key
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let template = strings[key]?[currentLanguage] ?? strings[key]?["zh"] ?? key
    return String(format: template, arguments: args)
}
