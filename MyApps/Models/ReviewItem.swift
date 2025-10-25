import Foundation

struct ReviewItem: Identifiable, Equatable {
    let reviewId: String
    let title: String
    let body: String
    let rating: Int
    let version: String
    let authorName: String
    let updatedDate: Date
    let rawJSON: [String: Any]

    var id: String { reviewId }

    init?(entry: [String: Any]) {
        guard let idDictionary = entry["id"] as? [String: Any],
              let reviewId = idDictionary["label"] as? String,
              let titleDictionary = entry["title"] as? [String: Any],
              let title = titleDictionary["label"] as? String,
              let contentDictionary = entry["content"] as? [String: Any],
              let rawBody = contentDictionary["label"] as? String,
              let ratingDictionary = entry["im:rating"] as? [String: Any],
              let ratingLabel = ratingDictionary["label"] as? String,
              let rating = Int(ratingLabel),
              let versionDictionary = entry["im:version"] as? [String: Any],
              let version = versionDictionary["label"] as? String,
              let authorDictionary = entry["author"] as? [String: Any],
              let authorNameDictionary = authorDictionary["name"] as? [String: Any],
              let authorName = authorNameDictionary["label"] as? String,
              let updatedDictionary = entry["updated"] as? [String: Any],
              let updatedLabel = updatedDictionary["label"] as? String,
              let updatedDate = ReviewItem.parseDate(updatedLabel)
        else {
            return nil
        }

        self.reviewId = reviewId
        self.title = ReviewItem.cleanText(title)
        self.body = ReviewItem.prepareBody(from: rawBody)
        self.rating = rating
        self.version = version
        self.authorName = authorName
        self.updatedDate = updatedDate
        self.rawJSON = entry
    }

    private static let isoDateFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func parseDate(_ string: String) -> Date? {
        if let date = isoDateFormatterWithFractional.date(from: string) {
            return date
        }
        return isoDateFormatter.date(from: string)
    }

    private static func cleanText(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func prepareBody(from value: String) -> String {
        var body = cleanText(value)
        body = body.replacingOccurrences(of: "\r\n", with: "\n")
        body = body.replacingOccurrences(of: "\r", with: "\n")
        body = decodeHTMLEntities(in: body)
        while body.contains("\n\n\n") {
            body = body.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return body
    }

    private static func decodeHTMLEntities(in text: String) -> String {
        guard let data = text.data(using: .utf8) else { return text }
        let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return cleanText(attributed?.string ?? text)
    }

    static func == (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        lhs.reviewId == rhs.reviewId
    }
}
