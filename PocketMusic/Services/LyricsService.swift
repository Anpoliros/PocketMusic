import Foundation
import AVFoundation

// MARK: - Lyrics Service
/// Service responsible for loading and parsing lyrics from various sources
/// Supports:
/// - External .lrc files (time-synced lyrics)
/// - Embedded lyrics in audio file metadata
/// - Plain text lyrics
class LyricsService {
    static let shared = LyricsService()

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Public Methods

    /// Load lyrics for a music file
    /// First tries to load from external .lrc file, then falls back to embedded lyrics
    /// - Parameter musicFile: The music file to load lyrics for
    /// - Returns: Lyrics object if found, nil otherwise
    func loadLyrics(for musicFile: MusicFile) async -> Lyrics? {
        // Try external LRC file first
        if let externalLyrics = await loadExternalLyrics(for: musicFile) {
            return externalLyrics
        }

        // Fall back to embedded lyrics
        if let embeddedLyrics = await loadEmbeddedLyrics(for: musicFile) {
            return embeddedLyrics
        }

        return nil
    }

    /// Load lyrics from external .lrc file
    /// - Parameter musicFile: The music file to find lyrics for
    /// - Returns: Lyrics object if .lrc file exists and is valid, nil otherwise
    func loadExternalLyrics(for musicFile: MusicFile) async -> Lyrics? {
        let lrcURL = musicFile.lyricsFileURL

        // Check if .lrc file exists
        guard fileManager.fileExists(atPath: lrcURL.path) else {
            return nil
        }

        do {
            // Read file contents
            let content = try String(contentsOf: lrcURL, encoding: .utf8)

            // Parse LRC content
            let lyrics = parseLRC(content: content, source: .externalFile(lrcURL))

            return lyrics.hasLyrics ? lyrics : nil
        } catch {
            print("❌ Error loading LRC file: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load embedded lyrics from audio file metadata
    /// - Parameter musicFile: The music file to extract lyrics from
    /// - Returns: Lyrics object if embedded lyrics exist, nil otherwise
    func loadEmbeddedLyrics(for musicFile: MusicFile) async -> Lyrics? {
        let asset = AVAsset(url: musicFile.url)

        do {
            let commonMetadata = try await asset.load(.commonMetadata)

            // Look for lyrics in metadata
            for item in commonMetadata {
                guard let key = item.commonKey?.rawValue else { continue }

                // Different metadata formats may use different keys for lyrics
                if key == "lyrics" || key == AVMetadataKey.commonKeyDescription.rawValue {
                    if let lyricsText = try? await item.load(.stringValue), !lyricsText.isEmpty {
                        // Check if embedded lyrics are in LRC format
                        if lyricsText.contains("[") && lyricsText.contains("]") {
                            let lyrics = parseLRC(content: lyricsText, source: .embedded)
                            if lyrics.hasLyrics {
                                return lyrics
                            }
                        }

                        // Plain text lyrics
                        return Lyrics(plainText: lyricsText, source: .embedded)
                    }
                }
            }

            return nil
        } catch {
            print("❌ Error loading embedded lyrics: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - LRC Parsing

    /// Parse LRC format lyrics
    /// LRC format specification:
    /// - Metadata tags: [tag:value]
    /// - Time tags: [mm:ss.xx] or [mm:ss.xxx]
    /// - Multiple time tags per line are supported
    ///
    /// Example:
    /// ```
    /// [ti:Song Title]
    /// [ar:Artist Name]
    /// [al:Album Name]
    /// [00:12.00]First line of lyrics
    /// [00:17.20]Second line of lyrics
    /// ```
    ///
    /// - Parameters:
    ///   - content: LRC file content as string
    ///   - source: Source of the lyrics
    /// - Returns: Parsed Lyrics object
    func parseLRC(content: String, source: Lyrics.Source) -> Lyrics {
        var metadata = LyricsMetadata()
        var lines: [LyricLine] = []

        // Split content into lines
        let contentLines = content.components(separatedBy: .newlines)

        for line in contentLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines
            guard !trimmedLine.isEmpty else { continue }

            // Check if line contains metadata tag
            if trimmedLine.hasPrefix("[") && !trimmedLine.contains("]") || trimmedLine.range(of: "\\[\\d+:", options: .regularExpression) == nil {
                parseMetadataLine(trimmedLine, into: &metadata)
                continue
            }

            // Parse lyric line with timestamps
            let parsedLines = parseLyricLine(trimmedLine)
            lines.append(contentsOf: parsedLines)
        }

        // Sort lines by timestamp
        lines.sort { $0.timestamp < $1.timestamp }

        // Calculate durations based on next line timestamps
        for i in 0..<lines.count {
            if i + 1 < lines.count {
                lines[i].duration = lines[i + 1].timestamp - lines[i].timestamp
            }
        }

        return Lyrics(
            syncedLines: lines.isEmpty ? nil : lines,
            source: source,
            metadata: metadata
        )
    }

    /// Parse a metadata line from LRC file
    /// Format: [tag:value]
    /// Supported tags: ti (title), ar (artist), al (album), au (author), by (creator), offset, length
    private func parseMetadataLine(_ line: String, into metadata: inout LyricsMetadata) {
        // Extract tag and value using regex
        let pattern = "\\[([a-z]+):(.+?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))

        for match in matches {
            guard match.numberOfRanges == 3 else { continue }

            let tag = nsLine.substring(with: match.range(at: 1)).lowercased()
            let value = nsLine.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)

            switch tag {
            case "ti":
                metadata.title = value
            case "ar":
                metadata.artist = value
            case "al":
                metadata.album = value
            case "au":
                metadata.author = value
            case "by":
                metadata.creator = value
            case "offset":
                metadata.offset = Int(value)
            case "length":
                metadata.length = value
            default:
                break
            }
        }
    }

    /// Parse a lyric line with timestamp(s)
    /// Format: [mm:ss.xx]lyrics text or [mm:ss.xx][mm:ss.xx]lyrics text (multiple timestamps)
    /// - Parameter line: Line to parse
    /// - Returns: Array of LyricLine objects (one for each timestamp)
    private func parseLyricLine(_ line: String) -> [LyricLine] {
        var lyricLines: [LyricLine] = []

        // Pattern to match timestamps: [mm:ss.xx] or [mm:ss.xxx]
        let timestampPattern = "\\[(\\d+):(\\d+\\.\\d+)\\]"
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else { return [] }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))

        // Extract all timestamps
        var timestamps: [TimeInterval] = []
        var lastMatchEnd = 0

        for match in matches {
            guard match.numberOfRanges == 3 else { continue }

            let minutesStr = nsLine.substring(with: match.range(at: 1))
            let secondsStr = nsLine.substring(with: match.range(at: 2))

            if let minutes = Double(minutesStr), let seconds = Double(secondsStr) {
                let timestamp = minutes * 60 + seconds
                timestamps.append(timestamp)
            }

            lastMatchEnd = match.range.location + match.range.length
        }

        // Extract lyrics text (everything after the last timestamp)
        let lyricsText = nsLine.substring(from: lastMatchEnd).trimmingCharacters(in: .whitespaces)

        // Skip if no text (instrumental break or empty line)
        guard !lyricsText.isEmpty else {
            // Still create entries for instrumental breaks
            return timestamps.map { LyricLine(timestamp: $0, text: "") }
        }

        // Create a LyricLine for each timestamp with the same text
        lyricLines = timestamps.map { LyricLine(timestamp: $0, text: lyricsText) }

        return lyricLines
    }
}

// MARK: - String Extensions for LRC Parsing
extension String {
    /// Remove all characters in a character set from the string
    func removing(charactersIn set: CharacterSet) -> String {
        let filtered = unicodeScalars.filter { !set.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}
