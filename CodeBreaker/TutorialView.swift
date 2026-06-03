import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pages: [(icon: String, title: String, items: [(String, String)])] = [
        (
            "lock.shield.fill",
            "游戏目标",
            [
                ("🎯", "系统生成一组隐藏的颜色密码"),
                ("🔢", "你需要在有限步数内猜出正确组合"),
                ("🏆", "步数越少，星级越高"),
            ]
        ),
        (
            "circle.grid.2x2.fill",
            "如何操作",
            [
                ("👆", "点击底部颜色球，放入猜测槽位"),
                ("🔄", "点击已放置的槽位可以移除"),
                ("📤", "填满所有位置后点击「提交」"),
            ]
        ),
        (
            "checkmark.circle.fill",
            "反馈含义",
            [
                ("🟢", "绿色 = 颜色正确，位置正确"),
                ("🟠", "橙色 = 颜色正确，位置不对"),
                ("⚪", "空圈 = 该颜色不在密码中"),
            ]
        ),
        (
            "theatermask.and.paintbrush.fill",
            "谎言模式",
            [
                ("🎭", "系统会给出 1 次虚假反馈"),
                ("🔍", "你需要通过逻辑识破哪步是假的"),
                ("⚠️", "谎言与真实值差距 ≤1，很隐蔽"),
                ("✅", "猜对时系统不会撒谎"),
            ]
        ),
        (
            "lightbulb.fill",
            "实用技巧",
            [
                ("💡", "每局有 1 次提示机会"),
                ("↩️", "撤销按钮可回退上一步猜测"),
                ("📊", "注意反馈模式，用排除法推理"),
                ("🧠", "先确定哪些颜色在密码中，再定位置"),
            ]
        ),
    ]

    var body: some View {
        ZStack {
            AppTheme.bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶栏
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 36, height: 36)
                            .glassCard(cornerRadius: 10)
                    }
                    Spacer()
                    Text("游戏教学")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // 内容
                let p = pages[page]
                VStack(spacing: 20) {
                    Image(systemName: p.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.accent)

                    Text(p.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(p.items.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 12) {
                                Text(p.items[i].0)
                                    .font(.system(size: 22))
                                    .frame(width: 30)
                                Text(p.items[i].1)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(20)
                    .glassCard(cornerRadius: 16)
                }
                .padding(.horizontal, 28)

                Spacer()

                // 分页指示 + 按钮
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { i in
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
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .glassCard(cornerRadius: 12)
                            }
                        }

                        Button {
                            if page < pages.count - 1 {
                                withAnimation(.spring(response: 0.3)) { page += 1 }
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text(page < pages.count - 1 ? "下一步" : "开始游戏！")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.bgDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }
        }
    }
}
