
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
        UserDefaults.standard.object(forKey: .countKey) as? Int
    }
}
