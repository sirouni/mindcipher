import SwiftUI

enum AppSkin: String, CaseIterable {
    case agent = "Agent"
    case cyber = "Cyber"
    case military = "Military"
    case minimal = "Minimal"

    var bgColors: (Color, Color) {
        switch self {
        case .agent:
            return (Color(red: 0.92, green: 0.95, blue: 0.98), Color(red: 0.85, green: 0.90, blue: 0.96))
        case .cyber:
            return (Color(red: 0.95, green: 0.91, blue: 0.98), Color(red: 0.90, green: 0.86, blue: 0.95))
        case .military:
            return (Color(red: 0.93, green: 0.95, blue: 0.90), Color(red: 0.88, green: 0.92, blue: 0.86))
        case .minimal:
            return (Color(red: 0.96, green: 0.96, blue: 0.97), Color(red: 0.92, green: 0.92, blue: 0.93))
        }
    }

    var accent: Color {
        switch self {
        case .agent: return Color(red: 0.05, green: 0.60, blue: 0.55)
        case .cyber: return Color(red: 0.72, green: 0.15, blue: 0.50)
        case .military: return Color(red: 0.35, green: 0.60, blue: 0.15)
        case .minimal: return Color(red: 0.25, green: 0.25, blue: 0.30)
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
        let saved = UserDefaults.standard.string(forKey: "app_skin") ?? "Agent"
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
            Text("Theme")
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
