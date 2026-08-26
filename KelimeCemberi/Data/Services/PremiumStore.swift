import Foundation
import Observation
import StoreKit

@MainActor @Observable
final class PremiumStore {
    static let monthlyID = "com.kelimecemberi.premium.monthly"
    static let yearlyID = "com.kelimecemberi.premium.yearly"
    static let productIDs: Set<String> = [monthlyID, yearlyID]

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var isLoading = false
    private(set) var message: String?
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refreshEntitlement()
            }
        }
        Task { await load() }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            await refreshEntitlement()
            message = products.isEmpty ? "Premium ürünleri App Store Connect’te yapılandırılmayı bekliyor." : nil
        } catch {
            message = "Premium bilgileri şu anda yüklenemiyor."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlement()
                message = "Premium etkinleştirildi. Reklamlar kaldırıldı."
            case .success(.unverified): message = "Satın alma doğrulanamadı."
            case .pending: message = "Satın alma onay bekliyor."
            case .userCancelled: break
            @unknown default: break
            }
        } catch { message = "Satın alma tamamlanamadı." }
    }

    func restore() async {
        do { try await AppStore.sync(); await refreshEntitlement(); message = isPremium ? "Premium geri yüklendi." : "Geri yüklenecek satın alma bulunamadı." }
        catch { message = "Satın almalar geri yüklenemedi." }
    }

    func refreshEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                entitled = true
            }
        }
        isPremium = entitled
    }
}
