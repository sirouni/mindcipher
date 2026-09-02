import SwiftUI

enum AppSkin: String, CaseIterable {
    case agent = "Agent"
    case cyber = "Cyber"
    case military = "Military"
    case dark = "Dark"

    var isDark: Bool { self == .dark }

    var colorScheme: ColorScheme { isDark ? .dark : .light }

    var bgColors: (Color, Color) {
        switch self {
        case .agent:
            return (Color(red: 0.92, green: 0.95, blue: 0.98), Color(red: 0.85, green: 0.90, blue: 0.96))
        case .cyber:
            return (Color(red: 0.95, green: 0.91, blue: 0.98), Color(red: 0.90, green: 0.86, blue: 0.95))
        case .military:
            return (Color(red: 0.94, green: 0.95, blue: 0.88), Color(red: 0.88, green: 0.90, blue: 0.80))
        case .dark:
            return (Color(red: 0.11, green: 0.13, blue: 0.18), Color(red: 0.07, green: 0.08, blue: 0.11))
        }
    }

    var accent: Color {
        switch self {
        case .agent: return Color(red: 0.05, green: 0.60, blue: 0.55)
        case .cyber: return Color(red: 0.72, green: 0.15, blue: 0.50)
        case .military: return Color(red: 0.32, green: 0.52, blue: 0.16)
        case .dark: return Color(red: 0.28, green: 0.78, blue: 0.72)
        }
    }

    var cardFill: Color {
        switch self {
        case .agent: return Color(red: 0.99, green: 0.995, blue: 1.0)
        case .cyber: return Color(red: 1.0, green: 0.97, blue: 0.995)
        case .military: return Color(red: 0.97, green: 0.98, blue: 0.90)
        case .dark: return Color(red: 0.16, green: 0.18, blue: 0.24)
        }
    }

    var cardFillStrong: Color {
        switch self {
        case .agent: return Color.white
        case .cyber: return Color(red: 1.0, green: 0.98, blue: 1.0)
        case .military: return Color(red: 0.99, green: 0.99, blue: 0.93)
        case .dark: return Color(red: 0.20, green: 0.22, blue: 0.30)
        }
    }

    var cardStroke: Color {
        switch self {
        case .agent: return Color.black.opacity(0.06)
        case .cyber: return Color(red: 0.72, green: 0.15, blue: 0.50).opacity(0.14)
        case .military: return Color(red: 0.32, green: 0.52, blue: 0.16).opacity(0.18)
        case .dark: return Color.white.opacity(0.10)
        }
    }

    var textPrimary: Color {
        isDark ? Color(white: 0.94) : Color(white: 0.12)
    }

    var textSecondary: Color {
        isDark ? Color(white: 0.70) : Color(white: 0.40)
    }

    var textMuted: Color {
        isDark ? Color(white: 0.52) : Color(white: 0.62)
    }

    var icon: String {
        switch self {
        case .agent: return "lock.shield.fill"
        case .cyber: return "bolt.shield.fill"
        case .military: return "shield.checkered"
        case .dark: return "moon.fill"
        }
    }

    var preview: LinearGradient {
        LinearGradient(colors: [bgColors.0, bgColors.1], startPoint: .top, endPoint: .bottom)
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
        let saved = UserDefaults.standard.string(forKey: "app_skin") ?? "Agent"
        if saved == "Minimal" {
            currentSkin = .dark
        } else {
            currentSkin = AppSkin(rawValue: saved) ?? .agent
        }
    }

    func applyTheme() {
        objectWillChange.send()
    }

    var bgGradient: LinearGradient {
        let c = currentSkin.bgColors
        return LinearGradient(colors: [c.0, c.1], startPoint: .top, endPoint: .bottom)
    }

    var accent: Color { currentSkin.accent }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("settings.theme"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
                .padding(.bottom, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppSkin.allCases, id: \.rawValue) { skin in
                    skinCard(skin)
                }
            }
        }
    }

    private func skinCard(_ skin: AppSkin) -> some View {
        let isSelected = themeManager.currentSkin == skin
        return Button {
            withAnimation(.spring(response: 0.3)) {
                themeManager.currentSkin = skin
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(skin.preview)
                        .frame(height: 70)
                    Image(systemName: skin.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(skin.accent)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? skin.accent : skin.cardStroke, lineWidth: isSelected ? 2 : 1)
                )

                Text(skin.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? skin.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
