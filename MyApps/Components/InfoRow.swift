import SwiftUI

struct InfoRow: View {
    let title: String
    let value: String?

    var body: some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Text(value).font(.body)
                Divider()
            }
        }
    }
}
