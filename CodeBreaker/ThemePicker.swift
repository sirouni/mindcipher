import SwiftUI

/// Two paper stocks. Everything else in the app is ink and one stamp red.
enum AppSkin: String, CaseIterable {
    case dossier = "Dossier"
    case nightDesk = "NightDesk"

    var isDark: Bool { self == .nightDesk }

    var colorScheme: ColorScheme { isDark ? .dark : .light }

    /// Page background.
    var paper: Color {
        switch self {
        case .dossier: return Color(red: 0.945, green: 0.914, blue: 0.839)   // #F1E9D6
        case .nightDesk: return Color(red: 0.118, green: 0.106, blue: 0.086) // #1E1B16
        }
    }

    /// Folder / secondary paper (used behind lists, trays, dividers).
    var paperFolder: Color {
        switch self {
        case .dossier: return Color(red: 0.910, green: 0.871, blue: 0.773)   // #E8DEC5
        case .nightDesk: return Color(red: 0.145, green: 0.129, blue: 0.106) // #25211B
        }
    }

    /// Archive-pouch kraft, browner than page paper.
    var kraft: Color {
        switch self {
        case .dossier: return Color(red: 0.784, green: 0.678, blue: 0.478)   // #C8AD7A
        case .nightDesk: return Color(red: 0.275, green: 0.227, blue: 0.157) // #463A28
        }
    }

    var kraftFlap: Color {
        switch self {
        case .dossier: return Color(red: 0.690, green: 0.565, blue: 0.365)   // #B0905D
        case .nightDesk: return Color(red: 0.216, green: 0.176, blue: 0.118) // #372D1E
        }
    }

    /// Card sheet laid on top of the page.
    var paperCard: Color {
        switch self {
        case .dossier: return Color(red: 0.965, green: 0.945, blue: 0.890)   // #F6F1E3
        case .nightDesk: return Color(red: 0.165, green: 0.145, blue: 0.118) // #2A251E
        }
    }

    /// Brighter sheet (selected state, inputs).
    var paperCardStrong: Color {
        switch self {
        case .dossier: return Color(red: 0.985, green: 0.973, blue: 0.937)   // #FBF8EF
        case .nightDesk: return Color(red: 0.205, green: 0.183, blue: 0.150) // #342F26
        }
    }

    var ink: Color {
        switch self {
        case .dossier: return Color(red: 0.169, green: 0.137, blue: 0.094)   // #2B2318
        case .nightDesk: return Color(red: 0.929, green: 0.894, blue: 0.812) // #EDE4CF
        }
    }

    var inkFaded: Color {
        switch self {
        case .dossier: return Color(red: 0.478, green: 0.431, blue: 0.353)   // #7A6E5A
        case .nightDesk: return Color(red: 0.612, green: 0.569, blue: 0.490) // #9C917D
        }
    }

    var inkMuted: Color {
        switch self {
        case .dossier: return Color(red: 0.663, green: 0.624, blue: 0.549)   // #A99F8C
        case .nightDesk: return Color(red: 0.420, green: 0.388, blue: 0.333) // #6B6355
        }
    }

    /// Hairline rules and card strokes.
    var rule: Color { ink.opacity(isDark ? 0.22 : 0.28) }

    /// Stamp red — the only chromatic accent.
    var stamp: Color {
        switch self {
        case .dossier: return Color(red: 0.722, green: 0.196, blue: 0.169)   // #B8322B
        case .nightDesk: return Color(red: 0.847, green: 0.286, blue: 0.247) // #D8493F
        }
    }

    /// Burnt ochre for hint coins / warnings. Always paired with an icon or text.
    var ochre: Color {
        switch self {
        case .dossier: return Color(red: 0.604, green: 0.420, blue: 0.122)   // #9A6B1F
        case .nightDesk: return Color(red: 0.831, green: 0.624, blue: 0.290) // #D49F4A
        }
    }

    var icon: String {
        switch self {
        case .dossier: return "doc.text"
        case .nightDesk: return "moon"
        }
    }

    var localizedName: String {
        switch self {
        case .dossier: return L("theme.dossier")
        case .nightDesk: return L("theme.nightDesk")
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentSkin: AppSkin {
        didSet {
            UserDefaults.standard.set(currentSkin.rawValue, forKey: "app_skin")
            applyTheme()
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_skin") ?? AppSkin.dossier.rawValue
        switch saved {
        case "Dark", "Minimal", AppSkin.nightDesk.rawValue:
            currentSkin = .nightDesk
        default:
            // Agent / Cyber / Military and anything unknown fold into the paper skin.
            currentSkin = .dossier
        }
    }

    func applyTheme() {
        objectWillChange.send()
    }

    var accent: Color { currentSkin.stamp }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    // Observe the language so the labels refresh when the user switches language
    // in Settings; otherwise SwiftUI keeps the stale strings from the previous locale.
    @ObservedObject private var language = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("settings.theme"))
                .font(AppFont.label(12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.leading, 4)
                .padding(.bottom, 2)

            HStack(spacing: 12) {
                ForEach(AppSkin.allCases, id: \.rawValue) { skin in
                    skinCard(skin)
                }
            }
        }
    }

    private func skinCard(_ skin: AppSkin) -> some View {
        let isSelected = themeManager.currentSkin == skin
        return Button {
            withAnimation(.easeOut(duration: 0.2)) {
                themeManager.currentSkin = skin
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(skin.paper)
                        .frame(height: 70)
                    VStack(spacing: 6) {
                        Rectangle().fill(skin.ink).frame(width: 46, height: 2)
                        Rectangle().fill(skin.inkFaded).frame(width: 30, height: 2)
                        Rectangle().fill(skin.inkMuted).frame(width: 38, height: 2)
                    }
                    Image(systemName: skin.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(skin.stamp)
                        .offset(x: 34, y: -20)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? skin.stamp : AppTheme.cardStroke, lineWidth: isSelected ? 2 : 1)
                )

                Text(skin.localizedName)
                    .font(AppFont.label(13, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
