import SwiftUI

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
                    Text("What's New").font(.headline)
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
