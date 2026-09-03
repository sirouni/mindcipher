import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = LanguageManager.shared
    @State private var page = 0
    private let totalPages = 7

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 36, height: 36)
                            .glassCard(cornerRadius: 10)
                    }
                    Spacer()
                    Text("\(page + 1)/\(totalPages)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                TabView(selection: $page) {
                    goalPage.tag(0)
                    pickPage.tag(1)
                    feedbackPage.tag(2)
                    notesPage.tag(3)
                    hintPage.tag(4)
                    liePage.tag(5)
                    tipsPage.tag(6)
                    Color.clear.tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.3), value: page)
                .onChange(of: page) { _, newPage in
                    if newPage >= totalPages { dismiss() }
                }

                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == page ? AppTheme.accent : AppTheme.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: page)
                    }
                }

                HStack(spacing: 12) {
                    if page > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3)) { page -= 1 }
                        } label: {
                            Text(L("tutorial.back"))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .glassCard(cornerRadius: 12)
                        }
                    }
                    Button {
                        if page < totalPages - 1 {
                            withAnimation(.spring(response: 0.3)) { page += 1 }
                        } else { dismiss() }
                    } label: {
                        Text(page < totalPages - 1 ? L("tutorial.next") : L("tutorial.go"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
            }
        }
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, language.locale)
    }

    // MARK: - Page 1: 目标

    private var goalPage: some View {
        VStack(spacing: 20) {
            Text(L("tutorial.t1"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // 模拟密码栏
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.bgCardLight)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppTheme.textMuted)
                        )
                }
            }

            Text(L("tutorial.d1"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 星级示例
            HStack(spacing: 20) {
                starsExample(3, L("tutorial.star.speed"))
                starsExample(2, L("tutorial.star.good"))
                starsExample(1, L("tutorial.star.pass"))
            }
            .padding(16)
            .glassCard(cornerRadius: 14)
        }
        .padding(.horizontal, 28)
    }

    private func starsExample(_ count: Int, _ label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < count ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(i < count ? AppTheme.warning : AppTheme.textMuted)
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 2: 操作

    private var pickPage: some View {
        VStack(spacing: 20) {
            Text(L("tutorial.t2"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // 模拟猜测行
            HStack(spacing: 8) {
                PegView(color: .red, size: 40)
                PegView(color: .green, size: 40)
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.bgCardLight)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4,4]))
                            .frame(width: 30, height: 30)
                    )
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.bgCardLight)
                    .frame(width: 44, height: 44)
            }
            .boardLayout()

            Image(systemName: "arrow.up")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.accent)

            // 模拟颜色选择器
            HStack(spacing: 10) {
                ForEach([PegColor.red, .green, .blue, .yellow, .purple, .orange], id: \.rawValue) { color in
                    PegView(color: color, size: 36)
                }
            }
            .boardLayout()

            Text(L("tutorial.d2"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Page 3: 反馈

    private var feedbackPage: some View {
        VStack(spacing: 20) {
            Text(L("tutorial.t3"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 12) {
                feedbackExample(
                    colors: [.red, .green, .blue, .yellow],
                    exact: 1, partial: 2, empty: 1,
                    explain: L("tutorial.ex1")
                )
                feedbackExample(
                    colors: [.green, .blue, .red, .yellow],
                    exact: 4, partial: 0, empty: 0,
                    explain: L("tutorial.ex2")
                )
            }

            HStack(spacing: 24) {
                tutorialDotLegend(type: .exact, label: L("tutorial.dot.exact"))
                tutorialDotLegend(type: .partial, label: L("tutorial.dot.partial"))
                tutorialDotLegend(type: .miss, label: L("tutorial.dot.miss"))
            }
            .padding(14)
            .glassCard(cornerRadius: 12)
        }
        .padding(.horizontal, 20)
    }

    private func feedbackExample(colors: [PegColor], exact: Int, partial: Int, empty: Int, explain: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<colors.count, id: \.self) { i in
                    PegView(color: colors[i], size: 30)
                }
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<exact, id: \.self) { _ in
                        FeedbackDotView(type: .exact, size: 18)
                    }
                    ForEach(0..<partial, id: \.self) { _ in
                        FeedbackDotView(type: .partial, size: 18)
                    }
                    ForEach(0..<empty, id: \.self) { _ in
                        FeedbackDotView(type: .miss, size: 18)
                    }
                }
            }
            .padding(10)
            .glassCard(cornerRadius: 10)
            .boardLayout()

            Text(explain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func tutorialDotLegend(type: FeedbackType, label: String) -> some View {
        VStack(spacing: 4) {
            FeedbackDotView(type: type, size: 18)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 4: 笔记系统

    private var notesPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.accent)

            Text(L("tutorial.notes"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // 模拟笔记网格
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: 36, height: 22)
                    ForEach(1...4, id: \.self) { i in
                        Text("P\(i)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 36, height: 22)
                    }
                }
                HStack(spacing: 0) {
                    PegView(color: .red, size: 24).frame(width: 36, height: 36)
                    noteDemoCell(.eliminated)
                    noteDemoCell(nil)
                    noteDemoCell(nil)
                    noteDemoCell(.confirmed)
                }
                HStack(spacing: 0) {
                    PegView(color: .green, size: 24).frame(width: 36, height: 36)
                    noteDemoCell(nil)
                    noteDemoCell(.eliminated)
                    noteDemoCell(.confirmed)
                    noteDemoCell(.eliminated)
                }
                HStack(spacing: 0) {
                    PegView(color: .blue, size: 24).frame(width: 36, height: 36)
                    noteDemoCell(.confirmed)
                    noteDemoCell(.eliminated)
                    noteDemoCell(.eliminated)
                    noteDemoCell(nil)
                }
            }
            .padding(10)
            .glassCard(cornerRadius: 12)
            .boardLayout()

            VStack(alignment: .leading, spacing: 6) {
                iconNoteRow("xmark", AppTheme.danger, L("tutorial.notes.x"))
                iconNoteRow("checkmark", AppTheme.accent, L("tutorial.notes.check"))
                iconNoteRow("circle.fill", AppTheme.textMuted, L("tutorial.notes.row"))
                iconNoteRow("arrow.down", AppTheme.accent, L("tutorial.notes.col"))
            }
            .padding(14)
            .glassCard(cornerRadius: 12)

            Text(L("tutorial.notes.d"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func noteDemoCell(_ marker: NoteMarker?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(marker == .eliminated ? AppTheme.danger.opacity(0.1) : marker == .confirmed ? AppTheme.accent.opacity(0.12) : Color(white: 0.94))
                .frame(width: 32, height: 32)
            if marker == .eliminated {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.danger)
            } else if marker == .confirmed {
                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.accent)
            }
        }
        .frame(width: 36, height: 36)
    }

    private func iconNoteRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 5: 提示系统

    private var hintPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.warning)

            Text(L("tutorial.hints"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // 提示币示例
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.warning)
                        .frame(width: 56, height: 56)
                        .glassCard(cornerRadius: 14)
                    Text("3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AppTheme.warning, in: Circle())
                        .offset(x: 4, y: -4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("tutorial.hints.coins"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(L("tutorial.hints.spend"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)

            VStack(alignment: .leading, spacing: 8) {
                Text(L("tutorial.hints.earn"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                hintEarnRow("trophy.fill", L("tutorial.hints.win"), L("tutorial.hints.reward"))
                hintEarnRow("calendar.badge.checkmark", L("tutorial.hints.login"), L("tutorial.hints.reward"))
            }
            .padding(14)
            .glassCard(cornerRadius: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(L("tutorial.hints.do"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                hintInfoRow("minus.circle", L("tutorial.hints.do1"))
                hintInfoRow("checkmark.circle", L("tutorial.hints.do2"))
                hintInfoRow("brain.head.profile", L("tutorial.hints.do3"))
            }
            .padding(14)
            .glassCard(cornerRadius: 12)
        }
        .padding(.horizontal, 28)
    }

    private func hintEarnRow(_ icon: String, _ text: String, _ reward: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.warning)
                .frame(width: 20)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(reward)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.warning)
        }
    }

    private func hintInfoRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 6: 谎言

    private var liePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.danger)

            Text(L("lie.mode"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.danger)

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Text("3").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.textMuted).frame(width: 16)
                    PegView(color: .blue, size: 26); PegView(color: .red, size: 26); PegView(color: .yellow, size: 26); PegView(color: .green, size: 26)
                    Spacer()
                    FeedbackDotView(type: .exact, size: 16)
                    FeedbackDotView(type: .partial, size: 16)
                    FeedbackDotView(type: .miss, size: 16)
                    FeedbackDotView(type: .miss, size: 16)
                }
                .padding(8)
                .glassCard(cornerRadius: 8)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundStyle(AppTheme.danger)
                    PegView(color: .red, size: 26); PegView(color: .green, size: 26); PegView(color: .blue, size: 26); PegView(color: .yellow, size: 26)
                    Spacer()
                    FeedbackDotView(type: .partial, size: 16)
                    FeedbackDotView(type: .partial, size: 16)
                    FeedbackDotView(type: .miss, size: 16)
                    FeedbackDotView(type: .miss, size: 16)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.danger.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.danger.opacity(0.3), lineWidth: 1)))
            }
            .padding(.horizontal, 8)
            .boardLayout()

            VStack(alignment: .leading, spacing: 6) {
                iconRuleRow("theatermask.and.paintbrush.fill", L("tutorial.lie.r1"))
                iconRuleRow("magnifyingglass", L("tutorial.lie.r2"))
                iconRuleRow("checkmark.shield.fill", L("tutorial.lie.r3"))
                iconRuleRow("brain.head.profile", L("tutorial.lie.r4"))
            }
            .padding(14)
            .glassCard(cornerRadius: 12)
        }
        .padding(.horizontal, 28)
    }

    private func iconRuleRow(_ systemName: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.danger)
                .frame(width: 20)
            Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 5: 技巧

    private var tipsPage: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.warning)

            Text(L("tutorial.tips"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 10) {
                iconTipCard("brain.head.profile", L("tutorial.tips.elim"), L("tutorial.tips.elim.d"))
                iconTipCard("chart.bar.fill", L("tutorial.tips.compare"), L("tutorial.tips.compare.d"))
            }
        }
        .padding(.horizontal, 28)
    }

    private func iconTipCard(_ systemName: String, _ title: String, _ desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.warning)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
                Text(desc).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .glassCard(cornerRadius: 10)
    }
}
