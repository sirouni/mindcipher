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
                    Text("All 480 levels unlocked!")
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
                            Text("All 480 levels, Free Play & Custom Level Editor")
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
            Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 8)
    }
}
