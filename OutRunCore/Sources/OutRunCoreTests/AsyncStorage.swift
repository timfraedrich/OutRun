actor AsyncStorage<T> {
    
    private var data: T
    
    init(_ data: T) {
        self.data = data
    }
    
    func set(_ data: T) {
        self.data = data
    }
    
    func get() -> T {
        data
    }
}
