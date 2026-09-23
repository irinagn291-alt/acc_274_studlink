import SwiftUI

/// At most six steps. Courier New carries load, links, marks and figures.
struct TypeScale: DynamicProperty {
    @ScaledMetric(relativeTo: .largeTitle) var displaySize: CGFloat = 44
    @ScaledMetric(relativeTo: .title3) var linkSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title2) var figureSize: CGFloat = 22
    @ScaledMetric(relativeTo: .subheadline) var markSize: CGFloat = 15
    @ScaledMetric(relativeTo: .body) var bodySize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) var captionSize: CGFloat = 13

    var chainDisplay: Font {
        Font.custom(Tokens.FontName.display, size: displaySize).weight(.bold)
    }

    var linkFace: Font {
        Font.custom(Tokens.FontName.display, size: linkSize).weight(.bold)
    }

    var figure: Font {
        Font.custom(Tokens.FontName.display, size: figureSize).weight(.bold)
    }

    var mark: Font {
        Font.custom(Tokens.FontName.display, size: markSize)
    }

    var body: Font {
        Font.system(size: bodySize)
    }

    var caption: Font {
        Font.system(size: captionSize)
    }

    var displayTracking: CGFloat { -0.5 }
    var markTracking: CGFloat { 1.2 }
}
