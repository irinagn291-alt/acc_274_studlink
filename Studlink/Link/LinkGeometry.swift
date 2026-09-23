import CoreGraphics
import Foundation

/// Parallel layout for the canvas stroke and the overlaid hit targets.
struct LinkFrame: Identifiable, Equatable, Sendable {
    var id: UUID
    var index: Int
    var rect: CGRect
    var isStud: Bool
}

struct ChainLayout: Equatable, Sendable {
    var frames: [LinkFrame]
    var shackle: CGRect
    var canvas: CGSize
}

enum LinkGeometry {
    static func layout(links: [Link], in size: CGSize) -> ChainLayout {
        let insetX = Spacing.s2
        let width = max(size.width - insetX * 2, Spacing.hit)
        let shackleHeight = max(Spacing.hit + Spacing.s3, 72)
        let gap = Spacing.s1
        let usable = max(size.height - shackleHeight - gap - Spacing.s2, Spacing.hit)
        let count = max(links.count, 1)
        let rawHeight = (usable - CGFloat(max(links.count - 1, 0)) * gap) / CGFloat(count)
        let linkHeight = max(Spacing.hit + Spacing.s1, min(104, rawHeight))
        var y = Spacing.s1
        var frames: [LinkFrame] = []
        frames.reserveCapacity(links.count)
        for (index, link) in links.enumerated() {
            let stud = index.isMultiple(of: 2)
            let inset = stud ? Spacing.s2 : Spacing.s1
            let rect = CGRect(x: insetX + inset, y: y, width: width - inset * 2, height: linkHeight)
            frames.append(LinkFrame(id: link.id, index: index, rect: rect, isStud: stud))
            y += linkHeight + gap
        }
        if links.isEmpty {
            y = Spacing.s1
        }
        let shackle = CGRect(
            x: insetX + Spacing.s3,
            y: min(y, size.height - shackleHeight - Spacing.s1),
            width: width - Spacing.s3 * 2,
            height: shackleHeight
        )
        return ChainLayout(frames: frames, shackle: shackle, canvas: size)
    }
}
