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

import SwiftUI

public struct HeartRateText: View {
    
    @Environment(\.locale) private var locale
    private let heartRate: UInt8
    
    private var text: String {
        Measurement<UnitFrequency>.FormatStyle.measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.rounded()
        )
        .locale(locale)
        .format(.init(value: Double(heartRate), unit: UnitFrequency(symbol: .init(localized: "unit_beats_per_minute", bundle: .module))))
    }
    
    public var body: some View {
        Text(text)
    }
    
    public init(_ heartRate: UInt8) {
        self.heartRate = heartRate
    }
}
