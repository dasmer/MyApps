import Foundation
import Combine

@MainActor
class ReviewsViewModel: ObservableObject {
    @Published private(set) var reviews: [ReviewItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var currentPage = 1
    @Published private(set) var hasMore = true
    @Published var lastError: String?

    private let trackId: Int
    private let countryCode: String
    private let languageCode: String?
    private let session: URLSession
    private var pageCache: [Int: [ReviewItem]] = [:]

    init(trackId: Int, countryCode: String, languageCode: String? = nil, session: URLSession = .shared) {
        self.trackId = trackId
        self.countryCode = countryCode
        self.languageCode = languageCode
        self.session = session
    }

    func loadFirstPage() {
        guard !isLoading else { return }
        lastError = nil
        isRefreshing = false
        reviews = []
        currentPage = 1
        hasMore = true
        pageCache.removeAll()
        Task { await fetchPage(page: 1) }
    }

    func loadNextPageIfNeeded(currentItem: ReviewItem?) {
        guard hasMore, !isLoading, !isRefreshing, let currentItem, currentItem == reviews.last else { return }
        let nextPage = currentPage + 1
        Task { await fetchPage(page: nextPage) }
    }

    func refresh() async {
        guard !isLoading else { return }
        isRefreshing = true
        lastError = nil
        reviews = []
        currentPage = 1
        hasMore = true
        pageCache.removeAll()
        await fetchPage(page: 1)
        isRefreshing = false
    }

    private func buildURL(page: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/\(countryCode)/rss/customerreviews/id=\(trackId)/sortBy=mostRecent/json"
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "page", value: "\(page)")]
        if let languageCode {
            queryItems.append(URLQueryItem(name: "l", value: languageCode))
        }
        components.queryItems = queryItems
        return components.url
    }

    private func fetchPage(page: Int) async {
        if let cached = pageCache[page], !cached.isEmpty {
            appendReviews(cached, for: page)
            return
        }

        guard let url = buildURL(page: page) else {
            lastError = "Failed to build reviews URL."
            hasMore = false
            return
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 30

        let attempts = 2
        for attempt in 0..<attempts {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if httpResponse.statusCode == 404 {
                    hasMore = false
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                let reviews = try parseReviews(from: data)
                if page <= 2 {
                    pageCache[page] = reviews
                }
                if reviews.isEmpty {
                    hasMore = false
                }
                appendReviews(reviews, for: page)
                return
            } catch {
                if attempt == attempts - 1 {
                    lastError = error.localizedDescription
                } else {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }

    private func parseReviews(from data: Data) throws -> [ReviewItem] {
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let root = jsonObject, let feed = root["feed"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        var entryItems: [[String: Any]] = []
        if let entries = feed["entry"] as? [[String: Any]] {
            entryItems = entries
        } else if let entry = feed["entry"] as? [String: Any] {
            entryItems = [entry]
        }

        guard !entryItems.isEmpty else { return [] }
        var results: [ReviewItem] = []
        for entry in entryItems {
            if let item = ReviewItem(entry: entry) {
                results.append(item)
            }
        }
        return results
    }

    private func appendReviews(_ newReviews: [ReviewItem], for page: Int) {
        guard !newReviews.isEmpty else { return }
        let existingIds = Set(reviews.map { $0.reviewId })
        let filtered = newReviews.filter { !existingIds.contains($0.reviewId) }
        guard !filtered.isEmpty else {
            if reviews.isEmpty {
                hasMore = false
            }
            return
        }
        reviews.append(contentsOf: filtered)
        currentPage = page
    }

#if DEBUG
    func applyPreview(reviews: [ReviewItem]) {
        self.reviews = reviews
        self.currentPage = 1
        self.hasMore = false
        self.lastError = nil
        self.isLoading = false
        self.isRefreshing = false
    }
#endif
}
