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
        HStack {
            Text("Most recent")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
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
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            .listRowBackground(Color.clear)
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
        VStack(alignment: .leading, spacing: 8) {
            header
            Text(review.body)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(bodyLineLimit)
            if shouldShowToggle {
                Button(isExpanded ? "Show less" : "Read more", action: onToggleExpanded)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            meta
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(review.title)
                .font(.headline)
                .foregroundStyle(.primary)
            HStack(alignment: .center, spacing: 6) {
                ratingStars
                Text("\(review.rating)/5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ratingStars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= review.rating ? "star.fill" : "star")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(index <= review.rating ? Color.yellow : Color.secondary)
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
               let feed = root?["feed"] as? [String: Any],
               let entries = feed["entry"] as? [[String: Any]] {
                let reviews = entries.dropFirst().compactMap { ReviewItem(entry: $0) }
                viewModel.applyPreview(reviews: reviews)
            }
            return viewModel
        }()
    )
}
