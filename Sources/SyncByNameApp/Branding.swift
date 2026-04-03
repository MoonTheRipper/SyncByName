import AppKit
import SwiftUI

enum BrandPalette {
    static let midnight = Color(red: 34 / 255, green: 48 / 255, blue: 71 / 255)
    static let deepOcean = Color(red: 27 / 255, green: 71 / 255, blue: 92 / 255)
    static let mint = Color(red: 118 / 255, green: 204 / 255, blue: 182 / 255)
    static let gold = Color(red: 217 / 255, green: 154 / 255, blue: 97 / 255)
    static let parchment = Color(red: 246 / 255, green: 238 / 255, blue: 221 / 255)
    static let ink = Color(red: 22 / 255, green: 28 / 255, blue: 41 / 255)
}

struct BrandIconView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BrandPalette.midnight, BrandPalette.deepOcean],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                    .fill(BrandPalette.parchment.opacity(0.96))
                    .frame(width: size * 0.68, height: size * 0.44)
                    .offset(y: size * 0.10)

                RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                    .fill(BrandPalette.parchment)
                    .frame(width: size * 0.26, height: size * 0.13)
                    .offset(x: -size * 0.14, y: -size * 0.11)

                BranchStrokeShape()
                    .stroke(BrandPalette.mint, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.50, height: size * 0.36)
                    .offset(y: size * 0.04)

                ArrowHeadShape()
                    .fill(BrandPalette.mint)
                    .frame(width: size * 0.15, height: size * 0.12)
                    .offset(x: size * 0.16, y: -size * 0.02)

                Circle()
                    .fill(BrandPalette.gold)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: -size * 0.17, y: size * 0.13)
            }
            .shadow(color: Color.black.opacity(0.12), radius: size * 0.08, x: 0, y: size * 0.04)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct BranchStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.24))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.24))
        return path
    }
}

private struct ArrowHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

@MainActor
enum BrandIconRenderer {
    static func makeImage(size: CGFloat) -> NSImage {
        let renderer = ImageRenderer(
            content: BrandIconView()
                .frame(width: size, height: size)
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        return renderer.nsImage ?? NSImage(size: NSSize(width: size, height: size))
    }
}
