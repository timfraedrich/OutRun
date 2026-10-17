import Foundation

/// The consumable In-App Purchase products offered in the tip jar, ordered by price.
enum TipProduct: String, CaseIterable, Identifiable {
    
    case small = "de.tadris.OutRun.iap.tip.small"
    case medium = "de.tadris.OutRun.iap.tip.medium"
    case large = "de.tadris.OutRun.iap.tip.large"

    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .small: "mug.fill"
        case .medium: "carrot.fill"
        case .large: "takeoutbag.and.cup.and.straw.fill"
        }
    }
}
