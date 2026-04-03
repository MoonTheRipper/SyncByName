import AppKit
import SwiftUI

enum BrandPalette {
    static let obsidian = Color(red: 2 / 255, green: 8 / 255, blue: 16 / 255)
    static let midnight = Color(red: 0 / 255, green: 32 / 255, blue: 64 / 255)
    static let deepOcean = Color(red: 16 / 255, green: 64 / 255, blue: 96 / 255)
    static let steel = Color(red: 32 / 255, green: 80 / 255, blue: 112 / 255)
    static let blueMist = Color(red: 160 / 255, green: 176 / 255, blue: 208 / 255)
    static let skyGlow = Color(red: 80 / 255, green: 144 / 255, blue: 192 / 255)
    static let cloud = Color(red: 240 / 255, green: 246 / 255, blue: 255 / 255)
    static let ink = Color(red: 10 / 255, green: 24 / 255, blue: 40 / 255)
}

struct BrandIconView: View {
    var body: some View {
        Group {
            if let image = BrandIconRenderer.loadImage() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BrandPalette.obsidian, BrandPalette.deepOcean],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(BrandPalette.cloud)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

@MainActor
enum BrandIconRenderer {
    static func loadImage() -> NSImage? {
        for bundle in [Bundle.main, Bundle.module] {
            if let url = bundle.url(forResource: "ScanByName", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }

        let fallbackURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("ScanByName.png")
        return NSImage(contentsOf: fallbackURL)
    }

    static func makeImage(size: CGFloat) -> NSImage {
        if let image = loadImage()?.copy() as? NSImage {
            image.size = NSSize(width: size, height: size)
            return image
        }

        let fallback = NSImage(
            systemSymbolName: "arrow.triangle.branch.circle.fill",
            accessibilityDescription: "Sync by Name icon"
        ) ?? NSImage(size: NSSize(width: size, height: size))
        fallback.size = NSSize(width: size, height: size)
        return fallback
    }
}
