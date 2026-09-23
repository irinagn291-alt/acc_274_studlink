import SwiftUI

/// Contact URL. Opens in the system browser, never a WebView shell.
struct ContactLink: View {
    static let url = URL(string: "https://studlink-proof.pro/contact-us")

    private var type = TypeScale()

    init() {}

    var body: some View {
        if let url = Self.url {
            SwiftUI.Link(destination: url) {
                HStack {
                    Text("Contact Studlink")
                        .font(type.body)
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Palette.muted)
                }
                .frame(minHeight: Spacing.hit)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Contact Studlink")
        }
    }
}
