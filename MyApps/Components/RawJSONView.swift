import SwiftUI

struct RawJSONView: View {
    let encodable: any Encodable
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(prettyJSONString(from: encodable) ?? "Unable to render JSON")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Raw JSON")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
