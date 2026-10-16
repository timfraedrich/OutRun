import OSLog
import StoreKit

/// Finishes tip transactions. Tips do not unlock any content, so there is nothing to deliver besides finishing the transaction.
@MainActor
final class TipJarService {
    
    private nonisolated static let logger = Logger(category: "TipJarService")
    
    /// Starts listening for transactions that do not originate from a purchase in the app, such as approved Ask to Buy requests, or that
    /// were left unfinished in a previous session.
    init() {
        Task { await observeTransactionUpdates() }
    }
    
    /// Finishes the transaction of a purchase made in the app.
    /// - returns: Whether the purchase succeeded with a verified transaction.
    static func handle(_ result: Product.PurchaseResult) async -> Bool {
        switch result {
        case .success(let verificationResult):
            await finish(verificationResult)
        case .pending, .userCancelled:
            false
        @unknown default:
            false
        }
    }
    
    private func observeTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            await Self.finish(verificationResult)
        }
    }
    
    @discardableResult
    private static func finish(_ verificationResult: VerificationResult<Transaction>) async -> Bool {
        switch verificationResult {
        case .verified(let transaction):
            await transaction.finish()
            logger.info("Finished tip transaction for \(transaction.productID).")
            return true
        case .unverified(let transaction, let error):
            await transaction.finish()
            logger.error("Finished unverified tip transaction for \(transaction.productID): \(error.localizedDescription).")
            return false
        }
    }
}
