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

    // Check if file is a supported audio file
    static let supportedFormats = ["mp3", "m4a", "aac", "wav", "flac", "aiff", "alac"]

    var isSupported: Bool {
        Self.supportedFormats.contains(fileExtension)
    }
}

// MARK: - Music Metadata
struct MusicMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtwork: UIImage?
    var duration: TimeInterval?
    var genre: String?
    var year: String?

    var displayTitle: String {
        title ?? "Unknown Title"
    }

    var displayArtist: String {
        artist ?? "Unknown Artist"
    }

    var displayAlbum: String {
        album ?? "Unknown Album"
    }
}
