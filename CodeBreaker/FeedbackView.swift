import SwiftUI
import UIKit

enum FeedbackSupport {
    static let githubIssueURL = URL(string: "https://github.com/sirouni/mindcipher/issues/new?template=feedback.yml")!
    static let emailAddress = "sirouni@msn.com"

    static var emailURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = emailAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Mind Cipher Feedback"),
            URLQueryItem(name: "body", value: emailBody)
        ]
        return components.url ?? URL(string: "mailto:\(emailAddress)")!
    }

    private static var emailBody: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let ios = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        return "\n\n———\nApp \(version) · \(model) · iOS \(ios)\n"
    }
}

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AppTheme.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    howItWorks
                    actions
                }
                .padding(20)
            }
        }
        .navigationTitle(L("feedback.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(ThemeManager.shared.currentSkin.colorScheme, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            DossierCaption(text: L("feedback.section"))
            Text(L("feedback.title"))
                .font(AppFont.display(24, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(L("feedback.lead"))
                .font(AppFont.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 4)
            Rectangle().fill(AppTheme.ink).frame(height: 1.5).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            noteRow(icon: "checkmark.seal.fill", text: L("feedback.pro"))
            TypewriterRule()
            noteRow(icon: "globe", text: L("feedback.public"))
        }
        .padding(16)
        .paperCard()
    }

    private func noteRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                openURL(FeedbackSupport.githubIssueURL)
            } label: {
                VStack(spacing: 4) {
                    Text(L("feedback.github"))
                        .font(AppFont.label(14, weight: .bold))
                    Text(L("feedback.github.sub"))
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.85)
                }
                .foregroundStyle(AppTheme.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
            }
            .accessibilityLabel(L("feedback.github"))
            .accessibilityIdentifier("feedback.github")

            Button {
                openURL(FeedbackSupport.emailURL)
            } label: {
                VStack(spacing: 4) {
                    Text(L("feedback.email"))
                        .font(AppFont.label(14, weight: .bold))
                    Text(L("feedback.email.sub"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .paperCard()
            .accessibilityLabel(L("feedback.email"))
            .accessibilityIdentifier("feedback.email")
        }
    }
}
