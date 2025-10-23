import Foundation

class AppSettings {
    private static let artistIdKey = "selectedArtistId"
    private static let artistNameKey = "selectedArtistName"
    private static let artistLinkUrlKey = "selectedArtistLinkUrl"

    static var selectedArtistId: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: artistIdKey)
            return value == 0 ? nil : value
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: artistIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: artistIdKey)
            }
        }
    }

    static var selectedArtistName: String? {
        get {
            UserDefaults.standard.string(forKey: artistNameKey)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: artistNameKey)
            } else {
                UserDefaults.standard.removeObject(forKey: artistNameKey)
            }
        }
    }

    static var selectedArtistLinkUrl: String? {
        get {
            UserDefaults.standard.string(forKey: artistLinkUrlKey)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: artistLinkUrlKey)
            } else {
                UserDefaults.standard.removeObject(forKey: artistLinkUrlKey)
            }
        }
    }

    static func saveArtist(_ artist: Artist) {
        selectedArtistId = artist.artistId
        selectedArtistName = artist.artistName
        selectedArtistLinkUrl = artist.artistLinkUrl
    }

    static func clearArtist() {
        selectedArtistId = nil
        selectedArtistName = nil
        selectedArtistLinkUrl = nil
    }
}
