import Foundation
import StoreKit

@Observable
class StoreManager {
    static let shared = StoreManager()

    // 产品 ID 定义
    let productIds = [
        "com.wxyapp.mustory.month",
        "com.wxyapp.mustory.year"
    ]

    var products: [Product] = []
    var purchasedProductIds: Set<String> = []
    var isPremium: Bool {
        !purchasedProductIds.isEmpty
    }

    private var updates: Task<Void, Never>? = nil

    private init() {
        // 开始监听交易更新
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - 获取产品信息
    func fetchProducts() async {
        let requestedIds = productIds.joined(separator: ", ")
        print("🧾 IAP fetchProducts start ids=[\(requestedIds)]")

        do {
            let storeProducts = try await Product.products(for: productIds)
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
                print("🧾 IAP fetchProducts success count=\(self.products.count)")
                for product in self.products {
                    let subscriptionGroupId = product.subscription?.subscriptionGroupID ?? "none"
                    print("🧾 IAP product id=\(product.id) displayName=\(product.displayName) price=\(product.displayPrice) type=\(product.type) subscriptionGroup=\(subscriptionGroupId)")
                }

                if self.products.isEmpty {
                    print("🧾 IAP fetchProducts empty requestedIds=[\(requestedIds)]")
                }
            }
        } catch {
            print("🧾 IAP fetchProducts failed error=\(error)")
            print("🧾 IAP fetchProducts failed type=\(type(of: error))")
        }
    }

    // MARK: - 购买产品
    func purchase(_ product: Product) async -> Bool {
        print("🧾 IAP purchase start id=\(product.id) displayName=\(product.displayName) price=\(product.displayPrice) type=\(product.type)")

        do {
            let result = try await product.purchase()
            print("🧾 IAP purchase returned id=\(product.id)")

            switch result {
            case .success(let verification):
                print("🧾 IAP purchase success verification received id=\(product.id)")
                // 验证交易
                switch verification {
                case .unverified(_, let error):
                    print("🧾 IAP transaction unverified id=\(product.id) error=\(error)")
                    return false
                case .verified(let transaction):
                    print("🧾 IAP transaction verified productID=\(transaction.productID) transactionID=\(transaction.id) originalID=\(transaction.originalID)")
                    // 交易成功，同步状态
                    await transaction.finish()
                    print("🧾 IAP transaction finished productID=\(transaction.productID)")
                    await updatePurchasedProducts()
                    return true
                }
            case .userCancelled:
                print("🧾 IAP purchase userCancelled id=\(product.id)")
                return false
            case .pending:
                print("🧾 IAP purchase pending id=\(product.id)")
                return false
            @unknown default:
                print("🧾 IAP purchase unknown result id=\(product.id)")
                return false
            }
        } catch {
            print("🧾 IAP purchase failed id=\(product.id) error=\(error)")
            print("🧾 IAP purchase failed type=\(type(of: error))")
            return false
        }
    }

    // MARK: - 恢复订阅
    func restorePurchases() async {
        print("🧾 IAP restore start")
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("🧾 IAP restore sync triggered")
        } catch {
            print("🧾 IAP restore failed error=\(error)")
            print("🧾 IAP restore failed type=\(type(of: error))")
        }
    }

    // MARK: - 更新已购状态
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedIds = Set<String>()

        // 遍历所有当前有效的权益（Current Entitlements）
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                print("🧾 IAP entitlement verified productID=\(transaction.productID) revocationDate=\(String(describing: transaction.revocationDate)) expirationDate=\(String(describing: transaction.expirationDate))")
                // 检查是否过期（仅针对自动续期订阅）
                if transaction.revocationDate == nil {
                    purchasedIds.insert(transaction.productID)
                }
            case .unverified:
                print("🧾 IAP entitlement unverified")
                break
            }
        }

        self.purchasedProductIds = purchasedIds
        print("🧾 IAP updated purchased IDs: \(purchasedIds)")
    }

    // MARK: - 监听后台交易更新
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            print("🧾 IAP observeTransactionUpdates start")
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    print("🧾 IAP transaction update verified productID=\(transaction.productID) transactionID=\(transaction.id)")
                case .unverified(_, let error):
                    print("🧾 IAP transaction update unverified error=\(error)")
                }
                await updatePurchasedProducts()
            }
        }
    }
}
