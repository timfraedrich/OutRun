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

/// Single entry cache for values derived from chart data, so they are only recomputed when their inputs change.
/// - note: Intentionally not observable, so reading or updating it from a view body never invalidates the view.
@MainActor
final class ChartMemo<Key: Equatable, Value> {
    
    private var entry: (key: Key, value: Value)?
    
    func value(for key: Key, compute: () -> Value) -> Value {
        if let entry, entry.key == key {
            return entry.value
        }
        let value = compute()
        entry = (key, value)
        return value
    }
}
