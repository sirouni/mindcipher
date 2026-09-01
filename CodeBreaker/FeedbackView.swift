import SwiftUI
import UIKit

enum FeedbackSupport {
    static let githubIssueURL = URL(string: "https://github.com/sirouni/mindcipher/issues/new?template=feedback.yml")!
    static let emailAddress = "mindcipher.app@outlook.com"

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
            AppTheme.bgGradient.ignoresSafeArea()

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
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accent)
            Text(L("feedback.lead"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            noteRow(icon: "checkmark.seal.fill", text: L("feedback.pro"))
            Divider().overlay(AppTheme.textMuted.opacity(0.2))
            noteRow(icon: "globe", text: L("feedback.public"))
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
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
                        .font(.system(size: 16, weight: .bold))
                    Text(L("feedback.github.sub"))
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(L("feedback.github"))
            .accessibilityIdentifier("feedback.github")

            Button {
                openURL(FeedbackSupport.emailURL)
            } label: {
                VStack(spacing: 4) {
                    Text(L("feedback.email"))
                        .font(.system(size: 15, weight: .semibold))
                    Text(L("feedback.email.sub"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .glassCard(cornerRadius: 12)
            .accessibilityLabel(L("feedback.email"))
            .accessibilityIdentifier("feedback.email")
        }
    }
}
