import UIKit
import SwiftUI

// MARK: - Color Extractor Service
class ColorExtractorService {
    static let shared = ColorExtractorService()

    // Extract dominant colors from an image
    func extractColors(from image: UIImage, count: Int = 3) -> [Color] {
        guard let cgImage = image.cgImage else {
            return [.blue, .purple, .pink] // Fallback colors
        }

        // Resize image for better performance
        let size = CGSize(width: 100, height: 100)
        let resizedImage = resizeImage(image: image, targetSize: size)

        guard let resizedCGImage = resizedImage.cgImage else {
            return [.blue, .purple, .pink]
        }

        // Get pixel data
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample colors from different regions
        var colors: [UIColor] = []
        let regions = [
            (x: width / 4, y: height / 4),
            (x: 3 * width / 4, y: height / 4),
            (x: width / 2, y: height / 2),
            (x: width / 4, y: 3 * height / 4),
            (x: 3 * width / 4, y: 3 * height / 4)
        ]

        for region in regions {
            let offset = (region.y * width + region.x) * bytesPerPixel
            let r = CGFloat(pixelData[offset]) / 255.0
            let g = CGFloat(pixelData[offset + 1]) / 255.0
            let b = CGFloat(pixelData[offset + 2]) / 255.0

            // Boost saturation for more vibrant colors
            let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
            colors.append(boostSaturation(color: color))
        }

        // Return the most distinct colors
        return colors.prefix(count).map { Color($0) }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func boostSaturation(color: UIColor, boost: CGFloat = 1.3) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Boost saturation
        saturation = min(saturation * boost, 1.0)

        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    // Generate a gradient from colors
    func createGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
