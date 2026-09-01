import SwiftUI
import StoreKit

struct StoreView: View {
    @ObservedObject private var store = StoreManager.shared
    @ObservedObject private var hintCoins = HintCoinManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                currentBalance
                proSection
                hintSection
                restoreButton
            }
            .padding(24)
        }
        .background(AppTheme.bgGradient.ignoresSafeArea())
        .navigationTitle("Store")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accent)
            Text("Store")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var currentBalance: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hint Coins")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("\(hintCoins.coins)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            if store.isPro {
                Label("Pro", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.1), in: Capsule())
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unlock Full Game")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if store.isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(L("store.pro.done"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 12)
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pro Unlock")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(L("store.pro.blurb"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }

                    let proProduct = store.products.first(where: { $0.id == StoreProduct.proUnlock.rawValue })
                    Button {
                        if let product = proProduct {
                            Task { await store.purchase(product) }
                        }
                    } label: {
                        Text(proProduct?.displayPrice ?? "$2.99")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(store.purchaseInProgress || proProduct == nil)
                }
                .padding(14)
                .glassCard(cornerRadius: 12)
            }
        }
    }

    private var hintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hint Coins")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            let hintProducts = store.products.filter { p in
                [StoreProduct.hintPack5.rawValue, StoreProduct.hintPack15.rawValue, StoreProduct.hintPack50.rawValue].contains(p.id)
            }

            if hintProducts.isEmpty {
                ForEach([StoreProduct.hintPack5, .hintPack15, .hintPack50], id: \.rawValue) { sp in
                    hintFallbackRow(sp)
                }
            } else {
                ForEach(hintProducts, id: \.id) { product in
                    hintProductRow(product)
                }
            }
        }
    }

    private func hintFallbackRow(_ sp: StoreProduct) -> some View {
        let price: String = {
            switch sp {
            case .hintPack5: return "$0.99"
            case .hintPack15: return "$1.99"
            case .hintPack50: return "$4.99"
            default: return ""
            }
        }()
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.warning)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sp.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(sp.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text(price)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.warning, in: Capsule())
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }

    private func hintProductRow(_ product: Product) -> some View {
        let storeProduct = StoreProduct(rawValue: product.id)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.warning)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(storeProduct?.displayName ?? product.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(storeProduct?.description ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Button {
                Task { await store.purchase(product) }
            } label: {
                Text(product.displayPrice)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.warning, in: Capsule())
            }
            .disabled(store.purchaseInProgress)
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text(L("paywall.restore"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 8)
    }
}

enum PaywallReason: String, Identifiable {
    case classicLevels
    case lieLevels
    case freePlay
    case editor
    case finishedClassicFree
    case finishedLieFree

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicLevels: return L("paywall.classic.title")
        case .lieLevels: return L("paywall.lie.title")
        case .freePlay: return L("paywall.free.title")
        case .editor: return L("paywall.editor.title")
        case .finishedClassicFree: return L("paywall.done.classic.title")
        case .finishedLieFree: return L("paywall.done.lie.title")
        }
    }

    var subtitle: String {
        switch self {
        case .classicLevels: return L("paywall.classic.sub")
        case .lieLevels: return L("paywall.lie.sub")
        case .freePlay: return L("paywall.free.sub")
        case .editor: return L("paywall.editor.sub")
        case .finishedClassicFree: return L("paywall.done.classic.sub")
        case .finishedLieFree: return L("paywall.done.lie.sub")
        }
    }

    var isLie: Bool {
        switch self {
        case .lieLevels, .finishedLieFree: return true
        default: return false
        }
    }
}

struct PaywallView: View {
    let reason: PaywallReason
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    private var accent: Color { reason.isLie ? AppTheme.danger : AppTheme.accent }

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Image(systemName: reason.isLie ? "theatermask.and.paintbrush.fill" : "lock.open.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(accent)
                .symbolEffect(.pulse, options: .nonRepeating)

            VStack(spacing: 8) {
                Text(reason.title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(reason.subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 10) {
                benefit("theatermask.and.paintbrush.fill", L("paywall.benefit.lie"), AppTheme.danger)
                benefit("target", L("paywall.benefit.classic"), AppTheme.accent)
                benefit("infinity", L("paywall.benefit.free"), AppTheme.warning)
                benefit("slider.horizontal.3", L("paywall.benefit.editor"), Color(red: 0.9, green: 0.4, blue: 0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 14)

            let proProduct = store.products.first(where: { $0.id == StoreProduct.proUnlock.rawValue })
            Button {
                if let product = proProduct {
                    Task {
                        if await store.purchase(product) {
                            dismiss()
                        }
                    }
                }
            } label: {
                VStack(spacing: 2) {
                    Text(proProduct?.displayPrice ?? "$2.99")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(L("paywall.price"))
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(store.purchaseInProgress)

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text(L("paywall.restore"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .background(AppTheme.bgGradient.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .onChange(of: store.isPro) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    private func benefit(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
