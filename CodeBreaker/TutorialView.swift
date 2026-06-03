import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    private let totalPages = 5

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

                Spacer()

                Group {
                    switch page {
                    case 0: goalPage
                    case 1: pickPage
                    case 2: feedbackPage
                    case 3: liePage
                    default: tipsPage
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == page ? AppTheme.accent : AppTheme.textMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                HStack(spacing: 12) {
                    if page > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3)) { page -= 1 }
                        } label: {
                            Text("上一步")
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
                        Text(page < totalPages - 1 ? "下一步" : "开始游戏！")
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
    }

    // MARK: - Page 1: 目标

    private var goalPage: some View {
        VStack(spacing: 20) {
            Text("破译隐藏密码")
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

            Text("系统生成了一组隐藏的颜色密码\n在有限步数内猜出正确组合")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // 星级示例
            HStack(spacing: 20) {
                starsExample(3, "速通")
                starsExample(2, "不错")
                starsExample(1, "通关")
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
            Text("选择颜色填入")
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

            Image(systemName: "arrow.up")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.accent)

            // 模拟颜色选择器
            HStack(spacing: 10) {
                ForEach([PegColor.red, .green, .blue, .yellow, .purple, .orange], id: \.rawValue) { color in
                    PegView(color: color, size: 36)
                }
            }

            Text("点击颜色球 → 填入槽位\n填满后点击提交")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Page 3: 反馈

    private var feedbackPage: some View {
        VStack(spacing: 20) {
            Text("解读反馈线索")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 12) {
                feedbackExample(
                    colors: [.red, .green, .blue, .yellow],
                    exact: 1, partial: 2, empty: 1,
                    explain: "1个位置完全正确，2个颜色对但位置错，1个不在密码中"
                )
                feedbackExample(
                    colors: [.green, .blue, .red, .yellow],
                    exact: 4, partial: 0, empty: 0,
                    explain: "全部正确！密码破译成功"
                )
            }

            HStack(spacing: 24) {
                dotLegend(color: AppTheme.accent, label: "位置正确")
                dotLegend(color: AppTheme.warning, label: "颜色对位置错")
                dotLegend(color: AppTheme.textMuted, label: "不在密码中", hollow: true)
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
                        Circle().fill(AppTheme.accent).frame(width: 10, height: 10)
                    }
                    ForEach(0..<partial, id: \.self) { _ in
                        Circle().fill(AppTheme.warning).frame(width: 10, height: 10)
                    }
                    ForEach(0..<empty, id: \.self) { _ in
                        Circle().stroke(AppTheme.textMuted, lineWidth: 1).frame(width: 10, height: 10)
                    }
                }
            }
            .padding(10)
            .glassCard(cornerRadius: 10)

            Text(explain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func dotLegend(color: Color, label: String, hollow: Bool = false) -> some View {
        VStack(spacing: 4) {
            if hollow {
                Circle().stroke(color, lineWidth: 1.5).frame(width: 12, height: 12)
            } else {
                Circle().fill(color).frame(width: 12, height: 12)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - Page 4: 谎言

    private var liePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "theatermask.and.paintbrush.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.danger)

            Text("谎言模式")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.danger)

            VStack(spacing: 10) {
                // 正常反馈行
                HStack(spacing: 6) {
                    Text("3").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.textMuted).frame(width: 16)
                    PegView(color: .blue, size: 26); PegView(color: .red, size: 26); PegView(color: .yellow, size: 26); PegView(color: .green, size: 26)
                    Spacer()
                    Circle().fill(AppTheme.accent).frame(width: 8, height: 8)
                    Circle().fill(AppTheme.warning).frame(width: 8, height: 8)
                    Circle().stroke(AppTheme.textMuted, lineWidth: 1).frame(width: 8, height: 8)
                    Circle().stroke(AppTheme.textMuted, lineWidth: 1).frame(width: 8, height: 8)
                }
                .padding(8)
                .glassCard(cornerRadius: 8)

                // 谎言反馈行（红色高亮）
                HStack(spacing: 6) {
                    Text("4").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.textMuted).frame(width: 16)
                    PegView(color: .red, size: 26); PegView(color: .green, size: 26); PegView(color: .blue, size: 26); PegView(color: .yellow, size: 26)
                    Spacer()
                    Circle().fill(AppTheme.warning).frame(width: 8, height: 8)
                    Circle().fill(AppTheme.warning).frame(width: 8, height: 8)
                    Circle().stroke(AppTheme.textMuted, lineWidth: 1).frame(width: 8, height: 8)
                    Circle().stroke(AppTheme.textMuted, lineWidth: 1).frame(width: 8, height: 8)
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundStyle(AppTheme.danger)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.danger.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.danger.opacity(0.3), lineWidth: 1)))
            }
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 6) {
                iconRuleRow("theatermask.and.paintbrush.fill", "有且仅有 1 次反馈是假的")
                iconRuleRow("magnifyingglass", "谎言与真实差距 ≤1")
                iconRuleRow("checkmark.shield.fill", "猜对时不会骗你")
                iconRuleRow("doc.text.magnifyingglass", "结束后揭示哪步是谎言")
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

            Text("实用技巧")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 10) {
                iconTipCard("brain.head.profile", "排除法", "先猜不同颜色确定哪些在密码中")
                iconTipCard("chart.bar.fill", "对比反馈", "比较两次猜测的差异来定位")
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
