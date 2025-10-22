import SwiftUI

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
