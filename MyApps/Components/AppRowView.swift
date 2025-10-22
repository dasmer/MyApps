import SwiftUI

struct AppRowView: View {
    let app: AppItem

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // App Icon
            AsyncImage(url: URL(string: app.artworkUrl100 ?? app.artworkUrl60 ?? app.artworkUrl512 ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 70, height: 70)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "app.dashed")
                                .foregroundStyle(.secondary)
                        )
                @unknown default:
                    EmptyView()
                        .frame(width: 70, height: 70)
                }
            }

            // App Info
            VStack(alignment: .leading, spacing: 5) {
                Text(app.trackName ?? "Unknown App")
                    .font(.system(.body, design: .default, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(app.sellerName ?? app.artistName ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Rating and Info Row
                HStack(spacing: 4) {
                    if let rating = app.averageUserRating {
                        HStack(spacing: 2) {
                            RatingView(rating: rating, size: .small)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                        .fixedSize()

                        if let count = app.userRatingCount, count > 0 {
                            Text("(\(formatCount(count)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }

                    if let price = app.formattedPrice {
                        if app.averageUserRating != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.quaternary)
                        }
                        Text(price)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(price == "Free" ? .green : .blue)
                            .fixedSize()
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            let formatted = Double(count) / 1000000.0
            return String(format: "%.1fM", formatted).replacingOccurrences(of: ".0M", with: "M")
        } else if count >= 10000 {
            let formatted = Double(count) / 1000.0
            return String(format: "%.0fK", formatted)
        } else if count >= 1000 {
            let formatted = Double(count) / 1000.0
            return String(format: "%.1fK", formatted).replacingOccurrences(of: ".0K", with: "K")
        } else {
            return "\(count)"
        }
    }
}
