import Foundation

struct Artist: Codable, Identifiable {
    let artistId: Int
    let artistName: String
    let artistLinkUrl: String?
 
    var id: Int { artistId }
}

struct ArtistSearchResponse: Codable {
    let resultCount: Int
    let results: [Artist]
}
