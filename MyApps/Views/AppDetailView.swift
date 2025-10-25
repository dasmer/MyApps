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
            VStack(alignment: .leading, spacing: 20) {
                header

                if let urlStr = app.trackViewUrl, let url = URL(string: urlStr) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("View in App Store", systemImage: "arrow.up.forward.app.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                whatsNewSection
                descriptionSection
                screenshotsSection
                detailsGrid

                Button {
                    showRawJSON.toggle()
                } label: {
                    Label("View Raw JSON", systemImage: "curlybraces")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(app.trackName ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshAppDetails()
        }
        .sheet(isPresented: $showRawJSON) {
            RawJSONView(encodable: app)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let writeReviewURL {
                    Menu {
                        Button {
                            openURL(writeReviewURL)
                        } label: {
                            Label("Write a Review", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More actions")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: URL(string: app.artworkUrl100 ?? app.artworkUrl60 ?? app.artworkUrl512 ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                case .failure:
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                @unknown default:
                    EmptyView()
                        .frame(width: 100, height: 100)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(app.trackName ?? "Unknown App")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)

                if let seller = app.sellerName ?? app.artistName {
                    Text(seller)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let rating = app.averageUserRating {
                        HStack(spacing: 4) {
                            RatingView(rating: rating, size: .medium)
                            Text(String(format: "%.1f", rating))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    if let count = app.userRatingCount, count > 0 {
                        Text("•")
                            .foregroundStyle(.quaternary)
                        Text("\(count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, app.trackId != nil ? 4 : 0)

                if let trackId = app.trackId {
                    NavigationLink {
                        ReviewsListView(
                            trackId: trackId,
                            countryCode: countryCode,
                            languageCode: preferredLanguageCode
                        )
                    } label: {
                        Label("See Reviews", systemImage: "text.bubble.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }

                if let price = app.formattedPrice {
                    Text(price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(price == "Free" ? .green : .blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(price == "Free" ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                        )
                }
            }

            Spacer()
        }
    }

    private var whatsNewSection: some View {
        Group {
            if let notes = app.releaseNotes, !notes.isEmpty {
                SectionCard(title: "What's New") {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var descriptionSection: some View {
        Group {
            if let desc = app.description, !desc.isEmpty {
                SectionCard(title: "About") {
                    Text(desc)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var screenshotsSection: some View {
        Group {
            if let screenshots = app.screenshotUrls, !screenshots.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Screenshots")
                        .font(.title3)
                        .fontWeight(.bold)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(screenshots, id: \.self) { urlStr in
                                AsyncImage(url: URL(string: urlStr)) { phase in
                                    switch phase {
                                    case .empty:
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.tertiarySystemGroupedBackground))
                                            .frame(width: 250, height: 540)
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 540)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                                    case .failure:
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 250, height: 540)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private var detailsGrid: some View {
        SectionCard(title: "Information") {
            VStack(spacing: 0) {
                InfoRow(title: "Version", value: app.version)
                InfoRow(title: "Bundle ID", value: app.bundleId)
                InfoRow(title: "Category", value: app.primaryGenreName)
                InfoRow(title: "Age Rating", value: app.trackContentRating ?? app.contentAdvisoryRating)
                InfoRow(title: "Languages", value: app.languageCodesISO2A?.joined(separator: ", "))
                InfoRow(title: "Min iOS", value: app.minimumOsVersion)
                InfoRow(title: "File Size", value: formatBytes(app.fileSizeBytes))
                InfoRow(title: "Release Date", value: formatDate(app.releaseDate))
                InfoRow(title: "Updated", value: formatDate(app.currentVersionReleaseDate))
                InfoRow(title: "Features", value: app.features?.joined(separator: ", "))
                InfoRow(title: "Advisories", value: app.advisories?.joined(separator: ", "))
                if let devices = app.supportedDevices {
                    InfoRow(title: "Supported Devices", value: "\(devices.count) devices", isLast: true)
                }
            }
        }
    }

    private func formatBytes(_ bytes: String?) -> String? {
        guard let bytes, let byteCount = Int64(bytes) else { return bytes }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: byteCount)
    }

    private func formatDate(_ dateString: String?) -> String? {
        guard let dateString else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func refreshAppDetails() async {
        guard let trackId = app.trackId else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let urlStr = "https://itunes.apple.com/lookup?id=\(trackId)&country=\(countryCode)"
            guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            let (data, response) = try await URLSession.shared.data(for: request)
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

    private var preferredLanguageCode: String? {
        Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    }

    private var writeReviewURL: URL? {
        guard let trackId = app.trackId else { return nil }
        return URL(string: "itms-apps://apps.apple.com/app/id\(trackId)?action=write-review")
    }
}
