import Foundation

// MARK: - Lyrics Model
/// Represents lyrics for a music track
/// Can be plain text or time-synced (LRC format)
struct Lyrics: Codable, Equatable {
    /// The source of the lyrics
    enum Source: Codable {
        /// Lyrics embedded in the audio file metadata
        case embedded

        /// Lyrics loaded from external .lrc file
        case externalFile(URL)

        /// Manually added lyrics
        case manual
    }

    /// Plain text lyrics (no timing information)
    var plainText: String?

    /// Time-synced lyrics (with timestamps)
    var syncedLines: [LyricLine]?

    /// Source of the lyrics
    var source: Source?

    /// Metadata from LRC file
    var metadata: LyricsMetadata?

    /// Check if lyrics have timing information
    var isSynced: Bool {
        syncedLines != nil && !(syncedLines?.isEmpty ?? true)
    }

    /// Check if lyrics exist (either plain or synced)
    var hasLyrics: Bool {
        (plainText != nil && !plainText!.isEmpty) || isSynced
    }

    /// Get all lyrics as plain text
    var allText: String {
        if let plainText = plainText, !plainText.isEmpty {
            return plainText
        }

        if let lines = syncedLines {
            return lines.map { $0.text }.joined(separator: "\n")
        }

        return ""
    }

    init(plainText: String? = nil, syncedLines: [LyricLine]? = nil, source: Source? = nil, metadata: LyricsMetadata? = nil) {
        self.plainText = plainText
        self.syncedLines = syncedLines
        self.source = source
        self.metadata = metadata
    }
}

// MARK: - Lyric Line
/// A single line of lyrics with timing information
struct LyricLine: Codable, Equatable, Identifiable {
    /// Unique identifier for SwiftUI list
    var id: UUID = UUID()

    /// Timestamp in seconds when this line should be displayed
    var timestamp: TimeInterval

    /// The lyrics text for this line
    var text: String

    /// Optional end timestamp (for enhanced LRC format)
    var endTimestamp: TimeInterval?

    /// Duration of this line (calculated from end timestamp or next line)
    var duration: TimeInterval?

    init(timestamp: TimeInterval, text: String, endTimestamp: TimeInterval? = nil) {
        self.timestamp = timestamp
        self.text = text
        self.endTimestamp = endTimestamp
        if let end = endTimestamp {
            self.duration = end - timestamp
        }
    }

    /// Check if this line should be highlighted at the given playback time
    func isActive(at time: TimeInterval, nextLineTimestamp: TimeInterval?) -> Bool {
        if let nextTimestamp = nextLineTimestamp {
            return time >= timestamp && time < nextTimestamp
        } else {
            return time >= timestamp
        }
    }
}

// MARK: - Lyrics Metadata
/// Metadata information from LRC file
struct LyricsMetadata: Codable, Equatable {
    /// Song title
    var title: String?

    /// Artist name
    var artist: String?

    /// Album name
    var album: String?

    /// Lyrics creator/author
    var author: String?

    /// LRC file creator application
    var creator: String?

    /// Offset in milliseconds to adjust timing
    var offset: Int?

    /// Length of the song
    var length: String?

    init(title: String? = nil, artist: String? = nil, album: String? = nil,
         author: String? = nil, creator: String? = nil, offset: Int? = nil, length: String? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.author = author
        self.creator = creator
        self.offset = offset
        self.length = length
    }
}

// MARK: - Extensions
extension Lyrics {
    /// Get the currently active lyric line at a specific playback time
    /// - Parameter time: Current playback time in seconds
    /// - Returns: The active lyric line, if any
    func currentLine(at time: TimeInterval) -> LyricLine? {
        guard let lines = syncedLines, !lines.isEmpty else { return nil }

        // Find the last line whose timestamp is less than or equal to current time
        var currentLine: LyricLine?
        for line in lines {
            if line.timestamp <= time {
                currentLine = line
            } else {
                break
            }
        }

        return currentLine
    }

    /// Get the index of the currently active lyric line
    /// - Parameter time: Current playback time in seconds
    /// - Returns: The index of the active line, or nil if no active line
    func currentLineIndex(at time: TimeInterval) -> Int? {
        guard let lines = syncedLines, !lines.isEmpty else { return nil }

        for (index, line) in lines.enumerated() {
            let nextTimestamp = index + 1 < lines.count ? lines[index + 1].timestamp : nil
            if line.isActive(at: time, nextLineTimestamp: nextTimestamp) {
                return index
            }
        }

        return nil
    }

    /// Get the next lyric line to be displayed
    /// - Parameter time: Current playback time in seconds
    /// - Returns: The next lyric line, if any
    func nextLine(at time: TimeInterval) -> LyricLine? {
        guard let lines = syncedLines else { return nil }

        for line in lines {
            if line.timestamp > time {
                return line
            }
        }

        return nil
    }
}
