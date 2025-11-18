import UIKit
import SwiftUI

// MARK: - Color Extractor Service
/// Service responsible for extracting dominant colors from images
/// Used to create dynamic backgrounds based on album artwork
///
/// Algorithm:
/// 1. Resize image to 100x100 for performance
/// 2. Sample colors from 5 strategic regions (corners and center)
/// 3. Boost saturation for more vibrant colors
/// 4. Return top N most vibrant colors
///
/// Design:
/// - Singleton pattern for global access
/// - Optimized for performance (downscaling, regional sampling)
/// - Decoupled from UI and business logic
class ColorExtractorService {
    /// Shared singleton instance
    static let shared = ColorExtractorService()

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Color Extraction

    /// Extract dominant colors from an image
    /// Samples from 5 strategic regions and returns the most vibrant colors
    ///
    /// - Parameters:
    ///   - image: The source image (typically album artwork)
    ///   - count: Number of colors to extract (default: 3)
    /// - Returns: Array of SwiftUI Color objects
    func extractColors(from image: UIImage, count: Int = 3) -> [Color] {
        // Validate image
        guard let cgImage = image.cgImage else {
            print("⚠️ Failed to get CGImage from UIImage, using fallback colors")
            return defaultFallbackColors()
        }

        // Resize for performance - 100x100 is sufficient for color extraction
        let targetSize = CGSize(width: 100, height: 100)
        let resizedImage = resizeImage(image: image, targetSize: targetSize)

        guard let resizedCGImage = resizedImage.cgImage else {
            print("⚠️ Failed to resize image, using fallback colors")
            return defaultFallbackColors()
        }

        // Extract pixel data from resized image
        let pixelData = extractPixelData(from: resizedCGImage, size: targetSize)

        // Sample colors from strategic regions
        let colors = sampleColorsFromRegions(
            pixelData: pixelData,
            width: Int(targetSize.width),
            height: Int(targetSize.height)
        )

        // Return requested number of colors
        let extractedColors = colors.prefix(count).map { Color($0) }

        print("✅ Extracted \(extractedColors.count) colors from image")
        return extractedColors
    }

    // MARK: - Image Processing

    /// Resize image to target size for faster processing
    /// Uses UIGraphicsImageRenderer for efficient rendering
    ///
    /// - Parameters:
    ///   - image: Source image
    ///   - targetSize: Desired output size
    /// - Returns: Resized UIImage
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Extract raw pixel data from CGImage
    /// Creates an RGBA pixel buffer for color sampling
    ///
    /// - Parameters:
    ///   - cgImage: Source CGImage
    ///   - size: Image dimensions
    /// - Returns: Array of pixel data (RGBA format, 4 bytes per pixel)
    private func extractPixelData(from cgImage: CGImage, size: CGSize) -> [UInt8] {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8 // 8 bits per color channel

        // Create pixel buffer
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        // Create bitmap context for drawing
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("⚠️ Failed to create CGContext")
            return pixelData
        }

        // Draw image into context to populate pixel data
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }

    // MARK: - Color Sampling

    /// Sample colors from strategic regions of the image
    /// Samples from 5 points: 4 corners (inner) and center
    /// This gives a good representation of the image's color palette
    ///
    /// - Parameters:
    ///   - pixelData: Raw pixel data (RGBA format)
    ///   - width: Image width in pixels
    ///   - height: Image height in pixels
    /// - Returns: Array of UIColor objects
    private func sampleColorsFromRegions(pixelData: [UInt8], width: Int, height: Int) -> [UIColor] {
        let bytesPerPixel = 4

        // Define sampling regions (avoid edges which may be white/transparent)
        // Sample from inner quarters and center
        let regions = [
            (x: width / 4, y: height / 4),           // Top-left inner
            (x: 3 * width / 4, y: height / 4),       // Top-right inner
            (x: width / 2, y: height / 2),           // Center
            (x: width / 4, y: 3 * height / 4),       // Bottom-left inner
            (x: 3 * width / 4, y: 3 * height / 4)    // Bottom-right inner
        ]

        var colors: [UIColor] = []

        for region in regions {
            // Calculate pixel offset in the buffer
            let offset = (region.y * width + region.x) * bytesPerPixel

            // Ensure offset is within bounds
            guard offset + 2 < pixelData.count else { continue }

            // Extract RGB values (normalize to 0.0-1.0)
            let r = CGFloat(pixelData[offset]) / 255.0
            let g = CGFloat(pixelData[offset + 1]) / 255.0
            let b = CGFloat(pixelData[offset + 2]) / 255.0

            // Create color and boost saturation for more vibrant appearance
            let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
            let vibrantColor = boostSaturation(color: color)
            colors.append(vibrantColor)
        }

        return colors
    }

    // MARK: - Color Enhancement

    /// Boost the saturation of a color to make it more vibrant
    /// Converts to HSB color space, multiplies saturation, and converts back
    ///
    /// - Parameters:
    ///   - color: Source UIColor
    ///   - boost: Saturation multiplier (default: 1.3 = 30% increase)
    /// - Returns: Enhanced UIColor with boosted saturation
    private func boostSaturation(color: UIColor, boost: CGFloat = 1.3) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        // Convert RGB to HSB color space
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Boost saturation (clamped to 1.0 maximum)
        saturation = min(saturation * boost, 1.0)

        // Also slightly boost brightness for very dark colors
        if brightness < 0.3 {
            brightness = min(brightness * 1.2, 1.0)
        }

        // Convert back to RGB
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    // MARK: - Gradient Creation

    /// Create a SwiftUI LinearGradient from an array of colors
    /// Gradient flows from top-leading to bottom-trailing (diagonal)
    ///
    /// - Parameter colors: Array of SwiftUI Color objects
    /// - Returns: LinearGradient for use in SwiftUI views
    func createGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Fallback Colors

    /// Default fallback colors when image extraction fails
    /// Returns a pleasant blue-purple-pink gradient
    ///
    /// - Returns: Array of fallback Color objects
    private func defaultFallbackColors() -> [Color] {
        [.blue, .purple, .pink]
    }
}
