import Foundation

struct LookupResponse: Codable {
    let resultCount: Int
    let results: [AppItem]
}
