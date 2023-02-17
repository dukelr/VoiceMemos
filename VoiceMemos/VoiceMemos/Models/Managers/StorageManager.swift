
import Foundation

private extension String {
    static let countKey = "count"
}

final class StorageManager {
    
    static let shared = StorageManager()
    
    private init() {}
    
    func saveCountRecordings(_ count: Int) {
        UserDefaults.standard.set(count, forKey: .countKey)
    }
    
    func loadCountRecordings() -> Int? {
        guard let count = UserDefaults.standard.object(forKey: .countKey) as? Int else { return nil }
        return count
    }
}
