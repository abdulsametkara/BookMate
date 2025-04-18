import Foundation

struct BookImageLinks: Codable, Equatable {
    var thumbnail: String
    var large: String
    
    var thumbnailURL: URL? {
        return URL(string: thumbnail)
    }
    
    var largeURL: URL? {
        return URL(string: large)
    }
} 