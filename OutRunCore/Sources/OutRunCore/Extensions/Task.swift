import Combine

extension Task: @retroactive Cancellable {
    
    func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(self)
    }
}
