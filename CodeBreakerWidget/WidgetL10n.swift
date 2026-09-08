import Foundation

private struct WTr {
    let zh: String
    let en: String
    let hant: String
    let ja: String
    let ko: String
    let es: String
    let ar: String
    let de: String
    let fr: String
    let he: String
    let pt: String
    let tr: String

    var dict: [String: String] {
        [
            "zh": zh, "en": en, "zh-Hant": hant, "ja": ja, "ko": ko, "es": es,
            "ar": ar, "de": de, "fr": fr, "he": he, "pt": pt, "tr": tr,
        ]
    }
}

private func widgetLanguageCode() -> String {
    let saved = DailyCalendar.appGroupDefaults.string(forKey: "settings_language") ?? "system"
    if saved != "system", !saved.isEmpty {
        return saved
    }
    for raw in Locale.preferredLanguages {
        let id = raw.replacingOccurrences(of: "_", with: "-").lowercased()
        if id.hasPrefix("zh-hant") || id.hasPrefix("zh-tw") || id.hasPrefix("zh-hk") || id.hasPrefix("zh-mo") {
            return "zh-Hant"
        }
        if id.hasPrefix("zh") { return "zh" }
        if id.hasPrefix("ja") { return "ja" }
        if id.hasPrefix("ko") { return "ko" }
        if id.hasPrefix("es") { return "es" }
        if id.hasPrefix("ar") { return "ar" }
        if id.hasPrefix("de") { return "de" }
        if id.hasPrefix("fr") { return "fr" }
        if id.hasPrefix("he") || id.hasPrefix("iw") { return "he" }
        if id.hasPrefix("pt") { return "pt" }
        if id.hasPrefix("tr") { return "tr" }
        if id.hasPrefix("en") { return "en" }
    }
    return "en"
}

private let widgetStrings: [String: [String: String]] = [
    "widget.display": WTr(zh: "每日挑战", en: "Daily Challenge", hant: "每日挑戰", ja: "デイリーチャレンジ", ko: "일일 도전", es: "Desafío diario", ar: "التحدي اليومي", de: "Tägliche Herausforderung", fr: "Défi du jour", he: "אתגר יומי", pt: "Desafio diário", tr: "Günlük görev").dict,
    "widget.desc": WTr(zh: "看连胜，回今日谜题", en: "Track your streak and open today", hant: "看連勝，回今日謎題", ja: "連続日数を見て今日へ", ko: "연속 기록을 보고 오늘 열기", es: "Sigue tu racha y abre el de hoy", ar: "تابع سلسلتك وافتح لغز اليوم", de: "Serie sehen und heutiges Rätsel öffnen", fr: "Vois ta série et ouvre le défi du jour", he: "עקוב אחרי הרצף ופתח את של היום", pt: "Veja a sequência e abra o de hoje", tr: "Serini gör, bugünü aç").dict,
    "widget.play": WTr(zh: "点此挑战", en: "Tap to play", hant: "點此挑戰", ja: "タップして挑戦", ko: "눌러서 도전", es: "Toca para jugar", ar: "اضغط للعب", de: "Tippen zum Spielen", fr: "Touche pour jouer", he: "הקש לשחק", pt: "Toque para jogar", tr: "Oynamak için dokun").dict,
    "widget.done": WTr(zh: "已完成", en: "Done!", hant: "已完成", ja: "クリア", ko: "완료", es: "¡Hecho!", ar: "تم!", de: "Fertig!", fr: "Fait !", he: "הושלם!", pt: "Feito!", tr: "Bitti!").dict,
    "widget.completed": WTr(zh: "今日已完成", en: "Completed", hant: "今日已完成", ja: "今日はクリア", ko: "오늘 완료", es: "Completado", ar: "مكتمل", de: "Erledigt", fr: "Terminé", he: "הושלם", pt: "Concluído", tr: "Tamamlandı").dict,
    "widget.lie": WTr(zh: "今日谎言", en: "Today's Lie", hant: "今日謊言", ja: "今日の嘘", ko: "오늘의 거짓말", es: "Mentira de hoy", ar: "كذبة اليوم", de: "Heutige Lüge", fr: "Mensonge du jour", he: "השקר של היום", pt: "Mentira de hoje", tr: "Bugünün yalanı").dict,
    "widget.solved": WTr(zh: "已结案", en: "Case closed", hant: "已結案", ja: "解決済", ko: "사건 종결", es: "Caso cerrado", ar: "القضية مغلقة", de: "Fall gelöst", fr: "Affaire classée", he: "התיק נסגר", pt: "Caso encerrado", tr: "Dosya kapandı").dict,
    "widget.streak": WTr(zh: "连续出勤", en: "day streak", hant: "連續出勤", ja: "連続日", ko: "연속 일", es: "días seguidos", ar: "أيام متتالية", de: "Tage in Folge", fr: "jours d’affilée", he: "ימים ברצף", pt: "dias seguidos", tr: "gün seri").dict,
    "widget.day": WTr(zh: "第 %d 天", en: "DAY #%d", hant: "第 %d 天", ja: "%d日目", ko: "%d일차", es: "DÍA #%d", ar: "اليوم #%d", de: "TAG #%d", fr: "JOUR #%d", he: "יום #%d", pt: "DIA #%d", tr: "GÜN #%d").dict,
]

func W(_ key: String) -> String {
    let lang = widgetLanguageCode()
    return widgetStrings[key]?[lang] ?? widgetStrings[key]?["en"] ?? key
}

func W(_ key: String, _ args: CVarArg...) -> String {
    String(format: W(key), arguments: args)
}
