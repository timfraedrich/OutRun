import Foundation
import OutRunCore

/// Cheap identity of sectioned chart data, derived from the section boundaries instead of every sample.
struct ChartSectionsKey: Equatable {
    
    private let sections: [Section]
    
    init<Element>(_ sections: CategorizedArray<Bool, Element>, timestamp: (Element) -> Date) {
        self.sections = sections.map { section in
            Section(
                category: section.category,
                count: section.elements.count,
                first: section.elements.first.map(timestamp),
                last: section.elements.last.map(timestamp)
            )
        }
    }
    
    private struct Section: Equatable {
        let category: Bool
        let count: Int
        let first: Date?
        let last: Date?
    }
}
