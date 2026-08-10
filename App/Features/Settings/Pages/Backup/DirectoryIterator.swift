import Foundation

struct DirectoryIterator: Sequence {
    let enumerator: FileManager.DirectoryEnumerator
    
    func makeIterator() -> AnyIterator<Any> {
        AnyIterator {
            enumerator.nextObject()
        }
    }
}
