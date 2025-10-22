import Foundation

struct AppItem: Codable, Identifiable {
    var id: Int {
        trackId ?? artistId ?? Int(UUID().uuidString.hashValue)
    }

    // Common identifiers
    let wrapperType: String?
    let kind: String?
    let artistId: Int?
    let artistName: String?
    let artistViewUrl: String?
    let trackId: Int?
    let trackName: String?
    let trackCensoredName: String?
    let trackViewUrl: String?
    let bundleId: String?
    let version: String?
    let sellerName: String?

    // Ratings
    let averageUserRating: Double?
    let averageUserRatingForCurrentVersion: Double?
    let userRatingCount: Int?
    let userRatingCountForCurrentVersion: Int?
    let trackContentRating: String?
    let contentAdvisoryRating: String?

    // Pricing
    let price: Double?
    let formattedPrice: String?
    let currency: String?

    // Descriptive
    let primaryGenreName: String?
    let primaryGenreId: Int?
    let genres: [String]?
    let genreIds: [String]?
    let description: String?
    let releaseDate: String?
    let currentVersionReleaseDate: String?
    let releaseNotes: String?
    let minimumOsVersion: String?
    let languageCodesISO2A: [String]?
    let isVppDeviceBasedLicensingEnabled: Bool?
    let isGameCenterEnabled: Bool?
    let features: [String]?
    let advisories: [String]?

    // Images
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
    let screenshotUrls: [String]?
    let ipadScreenshotUrls: [String]?
    let appletvScreenshotUrls: [String]?

    // Devices
    let supportedDevices: [String]?
    let fileSizeBytes: String?
}
