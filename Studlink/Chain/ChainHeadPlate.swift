import SwiftUI

/// Head of the chain. Live payout and the prove verb live here.
struct ChainHeadPlate: View {
    var load: Int
    var linkCount: Int
    var total: Int
    var canProve: Bool
    var proved: Bool
    var parted: Bool
    var swageLeft: Bool
    var onProof: () -> Void

    private var type = TypeScale()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(LinkLabel.payoutHeading())
                .font(type.mark)
                .tracking(type.markTracking)
                .foregroundStyle(Palette.ink)
                .textCase(.uppercase)
            Text(Figures.int(load))
                .font(type.chainDisplay)
                .tracking(type.displayTracking)
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("\(LinkLabel.payoutHeading()) \(Figures.int(load))")
            Text(subtitle)
                .font(type.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(LinkLabel.changeLeft(available: swageLeft && !proved && !parted))
                .font(type.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(LinkLabel.proveAction(locked: proved || parted), action: onProof)
                .buttonStyle(ChainButtonStyle())
                .disabled(!canProve)
                .accessibilityLabel(LinkLabel.proveAction(locked: proved || parted))
                .accessibilityHint("Locks the chain and fixes the payout at link count squared.")
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .hairlineFill()
    }

    private var subtitle: String {
        if parted {
            return "The chain parted. The payout is void."
        }
        if proved {
            return "Locked. Settle the fixtures to see if every link holds."
        }
        return LinkLabel.chainStatus(picked: linkCount, total: total, load: load)
    }
}
