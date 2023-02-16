
import Foundation

class Recording: Codable {
    var name: String
    var date: String
    var duration: String
    var url: URL
    
    init(name: String, date: String, duration: String, url: URL) {
        self.name = name
        self.date = date
        self.duration = duration
        self.url = url
    }
}
