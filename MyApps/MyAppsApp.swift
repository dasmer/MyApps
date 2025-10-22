import SwiftUI

@main
struct ArtistAppsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Root

struct ContentView: View {
    // Hard-code these
    private let artistId = 686614183
    private let countryCode = "us"

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var apps: [AppItem] = []

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && apps.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView("Fetching Apps…")
                    }
                    .padding(.top, 40)
                } else if let errorMessage, apps.isEmpty {
                    VStack(spacing: 12) {
                        Text(errorMessage).foregroundStyle(.red)
                        Button("Retry") { Task { await fetchApps() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 40)
                } else {
                    List(apps) { app in
                        NavigationLink {
                            AppDetailView(initialApp: app, countryCode: countryCode)
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: app.artworkUrl100 ?? app.artworkUrl60 ?? app.artworkUrl512 ?? "")) { phase in
                                    switch phase {
                                    case .empty: ProgressView().frame(width: 60, height: 60)
                                    case .success(let image): image.resizable().clipShape(RoundedRectangle(cornerRadius: 12)).frame(width: 60, height: 60)
                                    case .failure: Color.gray.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 12)).frame(width: 60, height: 60)
                                    @unknown default: EmptyView().frame(width: 60, height: 60)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.trackName ?? "Unknown App").font(.headline).lineLimit(1)
                                    Text(app.sellerName ?? app.artistName ?? "—")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    HStack(spacing: 8) {
                                        if let rating = app.averageUserRating {
                                            RatingView(rating: rating)
                                            Text(String(format: "%.2f", rating))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let count = app.userRatingCount {
                                            Text("(\(count))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let price = app.formattedPrice {
                                            Text(price)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await fetchApps()
                    }
                }
            }
            .navigationTitle("My Apps")
            .task {
                if apps.isEmpty { await fetchApps() }
            }
        }
    }

    private func fetchApps() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let urlStr = "https://itunes.apple.com/lookup?id=\(artistId)&entity=software&country=\(countryCode)&limit=200"
            guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(LookupResponse.self, from: data)
            let onlyApps = decoded.results.filter { ($0.kind ?? "") == "software" || ($0.wrapperType ?? "") == "software" }
            let sorted = onlyApps.sorted { ($0.trackName ?? "") < ($1.trackName ?? "") }
            apps = sorted
            if apps.isEmpty {
                errorMessage = "No apps found for this artist in \(countryCode.uppercased())."
            }
        } catch {
            errorMessage = "Failed to fetch apps. \(error.localizedDescription)"
        }
    }
}

// MARK: - Detail

struct AppDetailView: View {
    let countryCode: String
    @State private var app: AppItem
    @State private var showRawJSON = false
    @State private var isRefreshing = false
    @Environment(\.openURL) private var openURL

    init(initialApp: AppItem, countryCode: String) {
        self._app = State(initialValue: initialApp)
        self.countryCode = countryCode
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                whatsNewSection
                descriptionSection
                screenshotsSection
                detailsGrid
                actionsRow
            }
            .padding()
        }
        .navigationTitle(app.trackName ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshAppDetails()
        }
        .sheet(isPresented: $showRawJSON) {
            RawJSONView(encodable: app)
        }
        .task {
            // Optional: refresh when opening, but not required
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: app.artworkUrl100 ?? app.artworkUrl60 ?? app.artworkUrl512 ?? "")) { phase in
                switch phase {
                case .empty: ProgressView().frame(width: 80, height: 80)
                case .success(let image): image.resizable().clipShape(RoundedRectangle(cornerRadius: 16)).frame(width: 80, height: 80)
                case .failure: Color.gray.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 16)).frame(width: 80, height: 80)
                @unknown default: EmptyView().frame(width: 80, height: 80)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(app.trackName ?? "Unknown App")
                    .font(.title3).fontWeight(.semibold)
                    .lineLimit(2)
                if let seller = app.sellerName ?? app.artistName {
                    Text(seller).foregroundStyle(.secondary).lineLimit(1)
                }
                HStack(spacing: 8) {
                    if let rating = app.averageUserRating {
                        RatingView(rating: rating)
                        Text(String(format: "%.2f", rating))
                            .foregroundStyle(.secondary)
                    }
                    if let count = app.userRatingCount {
                        Text("(\(count))").foregroundStyle(.secondary)
                    }
                    if let price = app.formattedPrice {
                        Text(price).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
    }

    private var whatsNewSection: some View {
        Group {
            if let notes = app.releaseNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What’s New").font(.headline)
                    Text(notes)
                }
            }
        }
    }

    private var descriptionSection: some View {
        Group {
            if let desc = app.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.headline)
                    Text(desc).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var screenshotsSection: some View {
        Group {
            if let screenshots = app.screenshotUrls, !screenshots.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshots").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(screenshots, id: \.self) { urlStr in
                                AsyncImage(url: URL(string: urlStr)) { phase in
                                    switch phase {
                                    case .empty: ProgressView().frame(width: 220, height: 470)
                                    case .success(let image): image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 470)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    case .failure: Color.gray.opacity(0.2).frame(width: 220, height: 470).clipShape(RoundedRectangle(cornerRadius: 16))
                                    @unknown default: EmptyView().frame(width: 220, height: 470)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var detailsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details").font(.headline)
            InfoRow(title: "Version", value: app.version)
            InfoRow(title: "Bundle ID", value: app.bundleId)
            InfoRow(title: "Category", value: app.primaryGenreName)
            InfoRow(title: "Age Rating", value: app.trackContentRating ?? app.contentAdvisoryRating)
            InfoRow(title: "Languages", value: app.languageCodesISO2A?.joined(separator: ", "))
            InfoRow(title: "Min iOS", value: app.minimumOsVersion)
            InfoRow(title: "File Size (bytes)", value: app.fileSizeBytes)
            InfoRow(title: "Release Date", value: app.releaseDate)
            InfoRow(title: "Current Version Release", value: app.currentVersionReleaseDate)
            InfoRow(title: "Features", value: app.features?.joined(separator: ", "))
            InfoRow(title: "Advisories", value: app.advisories?.joined(separator: ", "))
            if let devices = app.supportedDevices {
                InfoRow(title: "Supported Devices", value: "\(devices.count) devices")
            }
        }
    }

    private var actionsRow: some View {
        HStack {
            if let urlStr = app.trackViewUrl, let url = URL(string: urlStr) {
                Button("View in App Store") { openURL(url) }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
            Button(showRawJSON ? "Hide Raw JSON" : "Show Raw JSON") {
                showRawJSON.toggle()
            }
            .buttonStyle(.bordered)
        }
    }

    private func refreshAppDetails() async {
        guard let trackId = app.trackId else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let urlStr = "https://itunes.apple.com/lookup?id=\(trackId)&country=\(countryCode)"
            guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(LookupResponse.self, from: data)
            if let fresh = decoded.results.first {
                app = fresh
            }
        } catch {
            // Silently ignore refresh errors in detail view
        }
    }
}

// MARK: - Models

struct LookupResponse: Codable {
    let resultCount: Int
    let results: [AppItem]
}

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

// MARK: - Components

struct InfoRow: View {
    let title: String
    let value: String?
    var body: some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Text(value).font(.body)
                Divider()
            }
        }
    }
}

struct RatingView: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Image(systemName: rating >= Double(i + 1) ? "star.fill" : (rating > Double(i) ? "star.leadinghalf.filled" : "star"))
                    .foregroundColor(.yellow)
                    .imageScale(.small)
            }
        }
        .accessibilityLabel("Average rating \(String(format: "%.2f", rating)) out of 5")
    }
}

struct RawJSONView: View {
    let encodable: any Encodable
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(prettyJSONString(from: encodable) ?? "Unable to render JSON")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Raw JSON")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Utilities

func prettyJSONString(from value: any Encodable) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(AnyEncodable(value)) else { return nil }
    return String(data: data, encoding: .utf8)
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: any Encodable) {
        self._encode = value.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
