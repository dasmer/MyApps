import SwiftUI

struct InfoRow: View {
    let title: String
    let value: String?
    var isLast: Bool = false

    var body: some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 120, alignment: .leading)

                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 10)

                if !isLast {
                    Divider()
                        .padding(.leading, 0)
                }
            }
        }
    }
}
