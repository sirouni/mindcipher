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
        .background(AppTheme.paper.ignoresSafeArea())
        .navigationTitle(L("store.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            DossierCaption(text: L("store.title"))
            Text(L("store.clearance"))
                .font(AppFont.display(26, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
            Rectangle().fill(AppTheme.ink).frame(height: 1.5).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentBalance: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                DossierCaption(text: L("store.informant"))
                Text("\(hintCoins.coins)")
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            if store.isPro {
                StampView(text: L("store.clearance"), tone: .red, size: 9, rotation: -8)
            }
        }
        .padding(16)
        .paperCard()
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DossierCaption(text: L("store.unlock"))
                .padding(.leading, 2)

            if store.isPro {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(AppTheme.accent)
                    Text(L("store.pro.done"))
                        .font(AppFont.body(14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paperCard()
            } else {
                let proProduct = store.products.first(where: { $0.id == StoreProduct.proUnlock.rawValue })
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("paywall.unlock"))
                                .font(AppFont.display(17, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(L("store.pro.blurb"))
                                .font(AppFont.body(12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        StampView(text: proProduct?.displayPrice ?? "$2.99", tone: .red, size: 13, rotation: -8)
                            .padding(.top, 4)
                    }

                    Button {
                        if let product = proProduct {
                            Task { await store.purchase(product) }
                        }
                    } label: { Text(L("paywall.unlock")) }
                    .buttonStyle(InkButtonStyle())
                    .disabled(store.purchaseInProgress || proProduct == nil)
                }
                .padding(14)
                .paperCard(fill: AppTheme.bgCardLight)
            }
        }
    }

    private var hintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DossierCaption(text: L("store.informant"))
                .padding(.leading, 2)

            let hintProducts = store.products.filter { p in
                [StoreProduct.hintPack5.rawValue, StoreProduct.hintPack15.rawValue, StoreProduct.hintPack50.rawValue].contains(p.id)
            }

            VStack(spacing: 0) {
                if hintProducts.isEmpty {
                    let fallbacks: [StoreProduct] = [.hintPack5, .hintPack15, .hintPack50]
                    ForEach(Array(fallbacks.enumerated()), id: \.element.rawValue) { i, sp in
                        hintRow(index: i + 1, title: sp.displayName, detail: sp.description, price: fallbackPrice(sp), last: i == fallbacks.count - 1, action: nil)
                    }
                } else {
                    ForEach(Array(hintProducts.enumerated()), id: \.element.id) { i, product in
                        let sp = StoreProduct(rawValue: product.id)
                        hintRow(index: i + 1, title: sp?.displayName ?? product.displayName, detail: sp?.description ?? "", price: product.displayPrice, last: i == hintProducts.count - 1) {
                            Task { await store.purchase(product) }
                        }
                    }
                }
            }
            .paperCard()
        }
    }

    private func fallbackPrice(_ sp: StoreProduct) -> String {
        switch sp {
        case .hintPack5: return "$0.99"
        case .hintPack15: return "$1.99"
        case .hintPack50: return "$4.99"
        default: return ""
        }
    }

    private func hintRow(index: Int, title: String, detail: String, price: String, last: Bool, action: (() -> Void)?) -> some View {
        HStack(spacing: 10) {
            Text(romanNumeral(index))
                .font(AppFont.label(11, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 26, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.display(14, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(AppFont.body(11))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button {
                action?()
            } label: {
                Text(price)
                    .font(AppFont.label(12, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(AppTheme.ink, lineWidth: 1))
            }
            .disabled(action == nil || store.purchaseInProgress)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { if !last { TypewriterRule().padding(.horizontal, 14) } }
    }

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text(L("paywall.restore"))
                .font(AppFont.label(12, weight: .regular))
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
                .fill(AppTheme.rule)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            StampView(text: L("store.clearance"), tone: .red, size: 14, rotation: -6)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text(reason.title)
                    .font(AppFont.display(24, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(reason.subtitle)
                    .font(AppFont.body(15))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            VStack(alignment: .leading, spacing: 10) {
                benefit("theatermask.and.paintbrush.fill", L("paywall.benefit.lie"), AppTheme.danger)
                benefit("target", L("paywall.benefit.classic"), AppTheme.accent)
                benefit("infinity", L("paywall.benefit.free"), AppTheme.warning)
                benefit("slider.horizontal.3", L("paywall.benefit.editor"), AppTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard()

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
                        .font(AppFont.display(18, weight: .bold))
                    Text(L("paywall.price"))
                        .font(AppFont.label(11, weight: .regular))
                        .opacity(0.9)
                }
                .foregroundStyle(AppTheme.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 3))
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
        .background(AppTheme.paper.ignoresSafeArea())
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
