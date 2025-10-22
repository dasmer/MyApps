import SwiftUI

enum StarSize {
    case small
    case medium
    case large

    var imageScale: Image.Scale {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }

    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title3
        }
    }
}

struct RatingView: View {
    let rating: Double
    var size: StarSize = .small

    var body: some View {
        HStack(spacing: size == .large ? 4 : 2) {
            ForEach(0..<5) { i in
                Image(systemName: starName(for: i))
                    .font(size.font)
                    .foregroundStyle(
                        rating >= Double(i + 1) || rating > Double(i) ?
                            .yellow : Color.gray.opacity(0.3)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
        .accessibilityLabel("Average rating \(String(format: "%.1f", rating)) out of 5")
    }

    private func starName(for index: Int) -> String {
        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating > Double(index) {
            return "star.leadinghalf.filled"
        } else {
            return "star.fill"
        }
    }
}
