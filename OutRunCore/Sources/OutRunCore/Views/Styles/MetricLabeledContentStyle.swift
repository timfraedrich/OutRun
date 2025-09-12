import SwiftUI

public struct MetricLabeledContentStyle: LabeledContentStyle {
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            configuration.label
                .textCase(.uppercase)
                .foregroundStyle(.tertiary)
                .font(size.labelFont)
            configuration.content
                .foregroundStyle(.primary)
                .font(size.contentFont)
        }
        .lineLimit(1)
    }
    
    public enum Size {
        case `default`
        case small
        
        fileprivate var labelFont: Font {
            switch self {
            case .default: .subheadline.weight(.bold)
            case .small: .caption.weight(.bold)
            }
        }
        
        fileprivate var contentFont: Font {
            switch self {
            case .default: .title2.weight(.bold)
            case .small: .headline.weight(.bold)
            }
        }
    }
}

public extension LabeledContentStyle where Self == MetricLabeledContentStyle {
    
    static var metric: Self { .init(size: .default) }
    
    static func metric(size: Self.Size) -> Self {
        .init(size: size)
    }
}

#Preview {
    LabeledContent("Distance", value: "7,12 km")
        .labeledContentStyle(.metric(size: .default))
}
