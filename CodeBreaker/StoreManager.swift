import Foundation
import StoreKit

enum StoreProduct: String, CaseIterable {
    case hintPack5 = "com.codebreaker.app.hints5"
    case hintPack15 = "com.codebreaker.app.hints15"
    case hintPack50 = "com.codebreaker.app.hints50"
    case proUnlock = "com.codebreaker.app.pro"

    var coinAmount: Int {
        switch self {
        case .hintPack5: return 5
        case .hintPack15: return 15
        case .hintPack50: return 50
        case .proUnlock: return 0
        }
    }

    var displayName: String {
        switch self {
        case .hintPack5: return "5 Hint Coins"
        case .hintPack15: return "15 Hint Coins"
        case .hintPack50: return "50 Hint Coins"
        case .proUnlock: return "Pro Unlock"
        }
    }

    var description: String {
        switch self {
        case .hintPack5: return "A small pack of hints"
        case .hintPack15: return "Best value for casual players"
        case .hintPack50: return "Never run out of hints"
        case .proUnlock: return "Unlock all levels, Free Play, Duel & Custom"
        }
    }
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: proKey) }
    }
    @Published var purchaseInProgress = false

    private let proKey = "store_is_pro"
    private var updateTask: Task<Void, Never>?

    static let freeLevelCap = 40

    private init() {
        #if DEBUG
        isPro = true
        #else
        isPro = UserDefaults.standard.bool(forKey: proKey)
        #endif
        updateTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        updateTask?.cancel()
    }

    func loadProducts() async {
        do {
            let ids = StoreProduct.allCases.map(\.rawValue)
            print("[Store] Requesting products: \(ids)")
            let fetched = try await Product.products(for: Set(ids))
            print("[Store] Loaded \(fetched.count) products: \(fetched.map { $0.id })")
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            print("[Store] Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleTransaction(transaction)
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result) {
                    await handleTransaction(transaction)
                }
            }
        } catch {
            print("Restore failed: \(error)")
        }
    }

    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        guard let storeProduct = StoreProduct(rawValue: transaction.productID) else { return }

        switch storeProduct {
        case .proUnlock:
            isPro = true
        case .hintPack5, .hintPack15, .hintPack50:
            HintCoinManager.shared.coins += storeProduct.coinAmount
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    func isLevelLocked(_ levelId: Int) -> Bool {
        !isPro && levelId > Self.freeLevelCap
    }
}

enum StoreError: Error {
    case verificationFailed
}
