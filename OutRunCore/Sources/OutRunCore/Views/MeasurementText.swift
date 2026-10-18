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

public struct MeasurementText<U: Dimension, R: RangeExpression<Int>>: View {
    
    @Environment(\.locale) private var locale
    private let measurement: Measurement<U>
    private let unit: U
    private let fractionLength: R
    
    private var text: String {
        Measurement<U>.FormatStyle.measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(fractionLength))
        )
        .locale(locale)
        .format(measurement.converted(to: unit))
    }
    
    public var body: some View {
        Text(text)
    }
    
    public init(_ measurement: Measurement<U>, unit: U, fractionLength: R) {
        self.measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
    
    public init(_ measurement: Measurement<U>, unit: U, fractionLength: R = 0...2) where R == ClosedRange<Int> {
        self.measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
}
