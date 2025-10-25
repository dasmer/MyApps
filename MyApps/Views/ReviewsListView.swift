import SwiftUI

struct ReviewsListView: View {
    @StateObject private var viewModel: ReviewsViewModel
    private let autoLoad: Bool
    private let countryCode: String
    @State private var expandedReviewIDs: Set<String> = []

    init(trackId: Int, countryCode: String, languageCode: String? = nil, autoLoad: Bool = true, viewModel: ReviewsViewModel? = nil) {
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: ReviewsViewModel(trackId: trackId, countryCode: countryCode, languageCode: languageCode))
        }
        self.autoLoad = autoLoad
        self.countryCode = countryCode
    }

    var body: some View {
        List {
            headerPill

            if viewModel.reviews.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                reviewsSection
            }

            footerLoader
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard autoLoad, viewModel.reviews.isEmpty else { return }
            viewModel.loadFirstPage()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.lastError {
                errorBanner(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding()
            }
        }
    }

    private var headerPill: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption2)
                Text("Most recent")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .shadow(color: Color.accentColor.opacity(0.25), radius: 4, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .accessibilityElement(children: .combine)
    }

    private var reviewsSection: some View {
        ForEach(viewModel.reviews) { review in
            ReviewRowView(
                review: review,
                isExpanded: expandedReviewIDs.contains(review.reviewId),
                onToggleExpanded: { toggleExpanded(for: review) }
            )
            .onAppear {
                viewModel.loadNextPageIfNeeded(currentItem: review)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var footerLoader: some View {
        Group {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                EmptyView()
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No reviews yet in \(countryCode.uppercased())")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 60)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func toggleExpanded(for review: ReviewItem) {
        if expandedReviewIDs.contains(review.reviewId) {
            expandedReviewIDs.remove(review.reviewId)
        } else {
            expandedReviewIDs.insert(review.reviewId)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Spacer()
            Button("Try again") {
                if viewModel.reviews.isEmpty {
                    Task { await viewModel.refresh() }
                } else if let last = viewModel.reviews.last {
                    viewModel.loadNextPageIfNeeded(currentItem: last)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8)
    }

}

private struct ReviewRowView: View {
    let review: ReviewItem
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: review.updatedDate)
    }

    private var bodyLineLimit: Int? {
        isExpanded ? nil : 6
    }

    private var shouldShowToggle: Bool {
        review.body.count > 240
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Divider()
                .background(Color.primary.opacity(0.1))

            Text(review.body)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(bodyLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            if shouldShowToggle {
                Button(action: onToggleExpanded) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show less" : "Read more")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                }
            }

            Divider()
                .background(Color.primary.opacity(0.1))

            meta
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(review.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            HStack(alignment: .center, spacing: 8) {
                ratingStars
                Text("\(review.rating)/5")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ratingStars: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= review.rating ? "star.fill" : "star")
                    .font(.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(index <= review.rating ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
        .accessibilityLabel("Rating \(review.rating) out of 5")
    }

    private var meta: some View {
        HStack(spacing: 4) {
            Text(review.authorName)
            Text("•")
            Text(formattedDate)
            Text("•")
            Text("v\(review.version)")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    ReviewsListView(
        trackId: 123456,
        countryCode: "us",
        languageCode: "en-US",
        autoLoad: false,
        viewModel: {
            let viewModel = ReviewsViewModel(trackId: 123456, countryCode: "us")
            if let url = Bundle.main.url(forResource: "StubReviews", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let feed = root["feed"] as? [String: Any],
               let entries = feed["entry"] as? [[String: Any]] {
                let reviews = entries.compactMap { ReviewItem(entry: $0) }
                viewModel.applyPreview(reviews: reviews)
            }
            return viewModel
        }()
    )
}
