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
