import SwiftUI

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
