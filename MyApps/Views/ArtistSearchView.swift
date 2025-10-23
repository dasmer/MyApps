import SwiftUI

struct ArtistSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var artists: [Artist] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    var onArtistSelected: (Artist) -> Void
    var showCancelButton: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if artists.isEmpty && !isSearching && searchText.isEmpty {
                    ContentUnavailableView(
                        "Search for Developers",
                        systemImage: "magnifyingglass",
                        description: Text("Enter a developer or company name to find their apps")
                    )
                } else if isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Search Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if artists.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "questionmark.circle",
                        description: Text("No developers found for '\(searchText)'")
                    )
                } else {
                    List(artists) { artist in
                        Button {
                            onArtistSelected(artist)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(artist.artistName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Find Developer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Developer name")
            .onChange(of: searchText) { oldValue, newValue in
                Task {
                    await searchArtists(query: newValue)
                }
            }
            .toolbar {
                if showCancelButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func searchArtists(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            artists = []
            return
        }

        // Debounce: wait a bit before searching
        try? await Task.sleep(for: .milliseconds(300))

        // Check if search text changed while we were waiting
        guard query == searchText else { return }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let urlStr = "https://itunes.apple.com/search?term=\(encodedQuery)&entity=software&attribute=softwareDeveloper&limit=20"
            guard let url = URL(string: urlStr) else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            // Decode as AppItem results to extract unique artists
            let decoded = try JSONDecoder().decode(LookupResponse.self, from: data)

            // Extract unique artists from the app results
            var uniqueArtists: [Int: Artist] = [:]
            for app in decoded.results {
                if let artistId = app.artistId,
                   let artistName = app.artistName,
                   uniqueArtists[artistId] == nil {
                    uniqueArtists[artistId] = Artist(
                        artistId: artistId,
                        artistName: artistName,
                        artistLinkUrl: app.artistViewUrl
                    )
                }
            }

            artists = Array(uniqueArtists.values).sorted { $0.artistName < $1.artistName }

        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            artists = []
        }
    }
}
