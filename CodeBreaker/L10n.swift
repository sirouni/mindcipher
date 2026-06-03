import Foundation

private let currentLanguage: String = "en"

private let strings: [String: [String: String]] = [
    // 主页
    "app.title":        ["zh": "密码破译局",       "en": "Code Breaker"],
    "app.subtitle":     ["zh": "CODE BREAKER",     "en": "CODE BREAKER"],
    "menu.daily":       ["zh": "每日挑战",         "en": "Daily Challenge"],
    "menu.daily.done":  ["zh": "今日已完成 ✓",     "en": "Done today ✓"],
    "menu.daily.todo":  ["zh": "今日尚未挑战",     "en": "Not yet today"],
    "menu.classic":     ["zh": "经典任务",         "en": "Classic Missions"],
    "menu.classic.sub": ["zh": "120个关卡 · 逐步解锁", "en": "120 levels · Unlock progressively"],
    "menu.lie":         ["zh": "谎言任务",         "en": "Lie Missions"],
    "menu.lie.sub":     ["zh": "120关 · 含1次虚假反馈", "en": "120 levels · 1 fake feedback"],
    "menu.free":        ["zh": "自由模式",         "en": "Free Play"],
    "menu.free.sub":    ["zh": "自定义难度 · 无限挑战", "en": "Custom difficulty · Endless"],
    "menu.duel":        ["zh": "双人对战",         "en": "Duel Mode"],
    "menu.duel.sub":    ["zh": "一人设密码 · 一人来破译", "en": "One sets · One cracks"],
    "menu.editor":      ["zh": "自定义关卡",       "en": "Custom Level"],
    "menu.editor.sub":  ["zh": "调整所有参数 · 创造挑战", "en": "All params · Create challenge"],

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
    "lie.fake":         ["zh": "虚假:",                        "en": "Fake:"],
    "lie.real":         ["zh": "→ 真实:",                      "en": "→ Real:"],
    "lie.feedback":     ["zh": "%d精确 %d位置",                "en": "%d exact %d partial"],
    "lie.notrigger":    ["zh": "本局谎言未触发（你赢得太快了！）", "en": "No lie triggered (you won too fast!)"],
    "lie.start":        ["zh": "开始谎言挑战",                 "en": "Start Lie Challenge"],
    "lie.toggle":       ["zh": "谎言模式",                     "en": "Lie Mode"],
    "lie.toggle.desc":  ["zh": "含1次虚假反馈",                "en": "Includes 1 fake feedback"],

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
]

func L(_ key: String) -> String {
    strings[key]?[currentLanguage] ?? strings[key]?["zh"] ?? key
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let template = strings[key]?[currentLanguage] ?? strings[key]?["zh"] ?? key
    return String(format: template, arguments: args)
}
