import Foundation
import SwiftUI

struct Artist: Codable, Identifiable {
    let artistId: Int
    let artistName: String
    let artistLinkUrl: String?

    var id: Int { artistId }
}

extension Artist {
    /// Returns initials for the artist name (e.g., "DAS INC" → "DI")
    var initials: String {
        let words = artistName.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            // Take first letter of first two words
            let first = words[0].prefix(1).uppercased()
            let second = words[1].prefix(1).uppercased()
            return first + second
        } else if let first = words.first {
            // Take first letter only
            return String(first.prefix(1).uppercased())
        }
        return "?"
    }

    /// Returns a consistent color based on the artist name hash
    var avatarColor: Color {
        let hash = abs(artistName.hashValue)
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange,
            .yellow, .green, .teal, .cyan, .indigo
        ]
        return colors[hash % colors.count]
    }
}

struct ArtistSearchResponse: Codable {
    let resultCount: Int
    let results: [Artist]
}
