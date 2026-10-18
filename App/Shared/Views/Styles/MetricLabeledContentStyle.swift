//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

import SwiftUI

struct MetricLabeledContentStyle: LabeledContentStyle {
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            configuration.label
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .font(size.labelFont)
            configuration.content
                .foregroundStyle(.primary)
                .font(size.contentFont)
        }
        .lineLimit(1)
    }
    
    enum Size {
        case large
        case regular
        case small
        
        fileprivate var labelFont: Font {
            switch self {
            case .large: .subheadline.weight(.bold)
            case .regular: .subheadline.weight(.bold)
            case .small: .caption.weight(.bold)
            }
        }
        
        fileprivate var contentFont: Font {
            switch self {
            case .large: .largeTitle.weight(.bold)
            case .regular: .title2.weight(.bold)
            case .small: .headline.weight(.bold)
            }
        }
    }
}

extension LabeledContentStyle where Self == MetricLabeledContentStyle {
    
    static var metric: Self { .init(size: .regular) }
    
    static func metric(size: Self.Size) -> Self {
        .init(size: size)
    }
}

#Preview {
    LabeledContent("Distance", value: "7,12 km")
        .labeledContentStyle(.metric(size: .small))
    LabeledContent("Distance", value: "7,12 km")
        .labeledContentStyle(.metric(size: .regular))
    LabeledContent("Distance", value: "7,12 km")
        .labeledContentStyle(.metric(size: .large))
}
