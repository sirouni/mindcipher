import SwiftUI

enum AppSkin: String, CaseIterable {
    case agent = "特工"
    case cyber = "赛博"
    case military = "军事"
    case minimal = "极简"

    var bgColors: (Color, Color) {
        switch self {
        case .agent:
            return (Color(red: 0.06, green: 0.07, blue: 0.15), Color(red: 0.03, green: 0.04, blue: 0.10))
        case .cyber:
            return (Color(red: 0.05, green: 0.0, blue: 0.15), Color(red: 0.02, green: 0.0, blue: 0.08))
        case .military:
            return (Color(red: 0.08, green: 0.10, blue: 0.06), Color(red: 0.04, green: 0.06, blue: 0.03))
        case .minimal:
            return (Color(red: 0.10, green: 0.10, blue: 0.12), Color(red: 0.06, green: 0.06, blue: 0.07))
        }
    }

    var accent: Color {
        switch self {
        case .agent: return Color(red: 0.0, green: 0.85, blue: 0.65)
        case .cyber: return Color(red: 0.7, green: 0.3, blue: 1.0)
        case .military: return Color(red: 0.6, green: 0.8, blue: 0.2)
        case .minimal: return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }

    var icon: String {
        switch self {
        case .agent: return "lock.shield.fill"
        case .cyber: return "bolt.shield.fill"
        case .military: return "shield.checkered"
        case .minimal: return "circle.grid.2x2.fill"
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
        let saved = UserDefaults.standard.string(forKey: "app_skin") ?? "特工"
        currentSkin = AppSkin(rawValue: saved) ?? .agent
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
            Text("主题")
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
                        .overlay(
                            Image(systemName: skin.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(skin.accent)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? skin.accent : Color.clear, lineWidth: 2)
                        )
                }

                Text(skin.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? skin.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
