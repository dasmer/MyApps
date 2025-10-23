import SwiftUI

struct ContentView: View {
    private let countryCode = "us"

    @State private var artistId: Int?
    @State private var artistName: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var apps: [AppItem] = []
    @State private var showingArtistSearch = false
    @State private var hasLoadedSavedArtist = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && apps.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Fetching Apps…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, apps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red.gradient)
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await fetchApps() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(apps) { app in
                        NavigationLink {
                            AppDetailView(initialApp: app, countryCode: countryCode)
                        } label: {
                            AppRowView(app: app)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await fetchApps()
                    }
                }
            }
            .navigationTitle(artistName ?? "My Apps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingArtistSearch = true
                    } label: {
                        Label("Change Developer", systemImage: "person.crop.circle.badge.magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showingArtistSearch) {
                ArtistSearchView { artist in
                    selectArtist(artist)
                }
            }
            .task {
                loadSavedArtist()
                if artistId != nil && apps.isEmpty {
                    await fetchApps()
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { hasLoadedSavedArtist && artistId == nil && !showingArtistSearch },
                set: { _ in }
            )) {
                ArtistSearchView(showCancelButton: false) { artist in
                    selectArtist(artist)
                }
                .interactiveDismissDisabled()
            }
        }
    }

    private func fetchApps() async {
        guard let artistId else { return }

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
            let sorted = onlyApps.sorted {
                let count1 = $0.userRatingCount ?? 0
                let count2 = $1.userRatingCount ?? 0
                return count1 > count2
            }
            apps = sorted
            if apps.isEmpty {
                errorMessage = "No apps found for this artist in \(countryCode.uppercased())."
            }
        } catch {
            errorMessage = "Failed to fetch apps. \(error.localizedDescription)"
        }
    }

    private func loadSavedArtist() {
        artistId = AppSettings.selectedArtistId
        artistName = AppSettings.selectedArtistName
        hasLoadedSavedArtist = true
    }

    private func selectArtist(_ artist: Artist) {
        AppSettings.saveArtist(artist)
        artistId = artist.artistId
        artistName = artist.artistName
        apps = []
        Task {
            await fetchApps()
        }
    }
}
