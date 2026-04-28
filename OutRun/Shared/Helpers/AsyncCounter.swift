import Foundation

actor AsyncCounter {
    
    var value: Int
    
    init(value: Int) {
        self.value = value
    }
    
    func increase() -> Int {
        value += 1
        return value
    }
}
