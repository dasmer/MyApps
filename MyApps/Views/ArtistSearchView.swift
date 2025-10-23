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
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(colorForName(artist.artistName).gradient)
                                    Text(initialsForName(artist.artistName))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 40, height: 40)

                                Text(artist.artistName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.insetGrouped)
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

            artists = Array(uniqueArtists.values).sorted { artist1, artist2 in
                let score1 = relevanceScore(name: artist1.artistName, query: query)
                let score2 = relevanceScore(name: artist2.artistName, query: query)

                if score1 != score2 {
                    return score1 > score2
                }
                // Tie-breaker: alphabetical
                return artist1.artistName < artist2.artistName
            }

        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            artists = []
        }
    }

    private func initialsForName(_ name: String) -> String {
        let words = name.components(separatedBy: .whitespaces)
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

    private func colorForName(_ name: String) -> Color {
        // Generate consistent color based on name hash
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange,
            .yellow, .green, .teal, .cyan, .indigo
        ]
        return colors[hash % colors.count]
    }

    private func relevanceScore(name: String, query: String) -> Int {
        let nameLower = name.lowercased()
        let queryLower = query.lowercased()

        // Exact match (highest priority)
        if nameLower == queryLower {
            return 1000
        }

        // Starts with query
        if nameLower.hasPrefix(queryLower) {
            // Bonus for closer length match
            let lengthDiff = abs(name.count - query.count)
            return 500 - lengthDiff
        }

        // Word boundary match - query matches start of any word
        let words = name.components(separatedBy: .whitespaces)
        for word in words {
            if word.lowercased().hasPrefix(queryLower) {
                let lengthDiff = abs(word.count - query.count)
                return 300 - lengthDiff
            }
        }

        // Contains query
        if nameLower.contains(queryLower) {
            // Bonus for earlier position in string
            if let range = nameLower.range(of: queryLower) {
                let position = nameLower.distance(from: nameLower.startIndex, to: range.lowerBound)
                return 100 - position
            }
            return 100
        }

        // No match
        return 0
    }
}
