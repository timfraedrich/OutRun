//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
