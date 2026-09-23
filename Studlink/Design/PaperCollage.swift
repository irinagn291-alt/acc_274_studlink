import SwiftUI

/// Cutout collage from the asset catalog. Decorative, never a control.
struct PaperCollage: View {
    var name: String
    var maxSide: CGFloat = 220

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxSide, maxHeight: maxSide)
            .clipped()
            .accessibilityHidden(true)
    }
}

struct EmptyBoard: View {
    var art: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void

    private var type = TypeScale()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Spacer(minLength: Spacing.s2)
            PaperCollage(name: art, maxSide: 240)
                .frame(maxWidth: .infinity)
            Text(headline)
                .font(type.chainDisplay)
                .tracking(type.displayTracking)
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .font(type.body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
            Button(actionTitle, action: action)
                .buttonStyle(ChainButtonStyle())
                .accessibilityLabel(actionTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, Spacing.s3)
        .padding(.bottom, Spacing.s2)
        .background(Palette.background)
    }
}

struct BoardError: View {
    var title: String
    var line: String
    var retryTitle: String = "Try again"
    var retry: () -> Void

    private var type = TypeScale()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(title)
                .font(type.linkFace)
                .foregroundStyle(Palette.ink)
            Text(line)
                .font(type.body)
                .foregroundStyle(Palette.muted)
            Button(retryTitle, action: retry)
                .buttonStyle(ChainButtonStyle(kind: .quiet))
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlineFill()
    }
}
