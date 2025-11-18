import Foundation
import UIKit

// MARK: - Music File Model
struct MusicFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let fileExtension: String
    var duration: TimeInterval?
    var metadata: MusicMetadata?

    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.fileExtension = url.pathExtension.lowercased()
    }

    var displayName: String {
        name
    }

    /// All supported audio formats
    /// Includes common formats: MP3, M4A, AAC, WAV, FLAC, AIFF, ALAC
    /// Lossless formats: FLAC, ALAC, WAV, AIFF
    /// Lossy formats: MP3, AAC, M4A, OGG, WMA, OPUS
    static let supportedFormats = [
        // Lossless formats
        "flac", "alac", "wav", "aiff", "aif", "ape", "wv",
        // Lossy formats
        "mp3", "m4a", "aac", "ogg", "oga", "opus", "wma",
        // Apple formats
        "caf", "m4b", "m4p",
        // Other formats
        "mp2", "mpa", "mp1"
    ]

    /// Check if the file format is supported
    var isSupported: Bool {
        Self.supportedFormats.contains(fileExtension)
    }

    /// Get the potential lyrics file URL (same directory, same name, .lrc extension)
    var lyricsFileURL: URL {
        url.deletingPathExtension().appendingPathExtension("lrc")
    }
}

// MARK: - Music Metadata
/// Contains all metadata information for a music file
/// Including title, artist, album, artwork, and lyrics
struct MusicMetadata {
    /// Track title from metadata
    var title: String?

    /// Artist name from metadata
    var artist: String?

    /// Album name from metadata
    var album: String?

    /// Album artwork image
    var albumArtwork: UIImage?

    /// Track duration in seconds
    var duration: TimeInterval?

    /// Music genre
    var genre: String?

    /// Release year
    var year: String?

    /// Track number in album
    var trackNumber: Int?

    /// Embedded or external lyrics
    var lyrics: Lyrics?

    /// Display title with fallback
    var displayTitle: String {
        title ?? "Unknown Title"
    }

    /// Display artist with fallback
    var displayArtist: String {
        artist ?? "Unknown Artist"
    }

    /// Display album with fallback
    var displayAlbum: String {
        album ?? "Unknown Album"
    }
}
