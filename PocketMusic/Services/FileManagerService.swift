import Foundation
import AVFoundation
import UIKit

// MARK: - File Manager Service
/// Service responsible for managing music files and directories
/// Handles:
/// - Scanning and organizing music files
/// - Importing files from external sources
/// - Extracting metadata from audio files
/// - Loading lyrics (integrated with LyricsService)
class FileManagerService: ObservableObject {
    /// Shared singleton instance
    static let shared = FileManagerService()

    /// System file manager
    private let fileManager = FileManager.default

    /// Lyrics service for loading lyrics
    private let lyricsService = LyricsService.shared

    /// Root music directory in app's documents folder
    private let musicDirectory: URL

    /// Initialize the service and create music directory if needed
    private init() {
        // Create a dedicated music directory in the app's documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.musicDirectory = documentsPath.appendingPathComponent("Music", isDirectory: true)

        // Create directory if it doesn't exist
        createMusicDirectoryIfNeeded()
    }

    /// Create the music directory if it doesn't exist
    private func createMusicDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: musicDirectory.path) {
            do {
                try fileManager.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
                print("✅ Created music directory at: \(musicDirectory.path)")
            } catch {
                print("❌ Failed to create music directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Scan Directory
    /// Recursively scan a directory and build a folder structure
    /// - Parameter url: The directory URL to scan
    /// - Returns: A Folder object containing subfolders and music files
    func scanDirectory(at url: URL) -> Folder {
        var subfolders: [Folder] = []
        var musicFiles: [MusicFile] = []

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return Folder(url: url)
        }

        // Get all items in current directory only (not recursive for this level)
        var directoryContents: [(URL, Bool)] = []

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for itemURL in contents {
                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = resourceValues.isDirectory ?? false
                directoryContents.append((itemURL, isDirectory))
            }
        } catch {
            print("Error scanning directory: \(error)")
        }

        // Process contents
        for (itemURL, isDirectory) in directoryContents {
            if isDirectory {
                // Recursively scan subfolder
                let subfolder = scanDirectory(at: itemURL)
                if !subfolder.isEmpty {
                    subfolders.append(subfolder)
                }
            } else {
                // Check if it's a music file
                let musicFile = MusicFile(url: itemURL)
                if musicFile.isSupported {
                    musicFiles.append(musicFile)
                }
            }
        }

        return Folder(url: url, subfolders: subfolders, musicFiles: musicFiles)
    }

    // MARK: - Import Files
    /// Import music files from external sources
    /// Supports both individual files and entire directories
    /// Also imports associated .lrc files if they exist
    /// - Parameters:
    ///   - sourceURLs: Array of URLs to import (files or directories)
    ///   - preserveStructure: Whether to preserve the original folder structure
    /// - Returns: Array of imported MusicFile objects
    /// - Throws: File system errors if import fails
    func importFiles(from sourceURLs: [URL], preserveStructure: Bool = true) async throws -> [MusicFile] {
        var importedFiles: [MusicFile] = []

        for sourceURL in sourceURLs {
            // Start accessing security-scoped resource (required for iOS file access)
            guard sourceURL.startAccessingSecurityScopedResource() else {
                print("⚠️ Failed to access security-scoped resource: \(sourceURL.path)")
                continue
            }

            defer { sourceURL.stopAccessingSecurityScopedResource() }

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory)

            if isDirectory.boolValue {
                // Import entire directory recursively
                let files = try await importDirectory(from: sourceURL, preserveStructure: preserveStructure)
                importedFiles.append(contentsOf: files)
            } else {
                // Import single file
                if let file = try await importFile(from: sourceURL) {
                    importedFiles.append(file)

                    // Also try to import associated .lrc file if it exists
                    await importAssociatedLyricsFile(for: sourceURL, baseURL: nil, preserveStructure: preserveStructure)
                }
            }
        }

        return importedFiles
    }

    /// Import all music files from a directory recursively
    /// - Parameters:
    ///   - sourceURL: Source directory URL
    ///   - preserveStructure: Whether to preserve folder structure
    /// - Returns: Array of imported music files
    /// - Throws: File system errors
    private func importDirectory(from sourceURL: URL, preserveStructure: Bool) async throws -> [MusicFile] {
        var importedFiles: [MusicFile] = []

        let enumerator = fileManager.enumerator(at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey])

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

            if resourceValues.isDirectory == false {
                let musicFile = MusicFile(url: fileURL)
                if musicFile.isSupported {
                    // Import the music file
                    if let importedFile = try await importFile(from: fileURL, preserveStructure: preserveStructure, baseURL: sourceURL) {
                        importedFiles.append(importedFile)

                        // Import associated lyrics file if it exists
                        await importAssociatedLyricsFile(for: fileURL, baseURL: sourceURL, preserveStructure: preserveStructure)
                    }
                }
            }
        }

        return importedFiles
    }

    /// Import a single music file
    /// - Parameters:
    ///   - sourceURL: Source file URL
    ///   - preserveStructure: Whether to preserve folder structure
    ///   - baseURL: Base directory URL (for calculating relative path)
    /// - Returns: Imported MusicFile or nil if file is not supported
    /// - Throws: File system errors
    private func importFile(from sourceURL: URL, preserveStructure: Bool = true, baseURL: URL? = nil) async throws -> MusicFile? {
        let musicFile = MusicFile(url: sourceURL)
        guard musicFile.isSupported else { return nil }

        let destinationURL: URL

        if preserveStructure, let baseURL = baseURL {
            // Preserve directory structure relative to base URL
            let relativePath = sourceURL.path.replacingOccurrences(of: baseURL.path, with: "")
            destinationURL = musicDirectory.appendingPathComponent(relativePath)

            // Create intermediate directories
            let destinationDirectory = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        } else {
            // Flat import - all files go to root music directory
            destinationURL = musicDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        }

        // Copy file if it doesn't exist, skip if already imported
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("✅ Imported: \(sourceURL.lastPathComponent)")
        } else {
            print("⏭️ Skipped (already exists): \(sourceURL.lastPathComponent)")
        }

        return MusicFile(url: destinationURL)
    }

    /// Import associated .lrc lyrics file if it exists in the same directory
    /// - Parameters:
    ///   - musicFileURL: The music file URL
    ///   - baseURL: Base directory URL (for calculating relative path)
    ///   - preserveStructure: Whether to preserve folder structure
    private func importAssociatedLyricsFile(for musicFileURL: URL, baseURL: URL?, preserveStructure: Bool) async {
        // Check if .lrc file exists in the same directory
        let lrcURL = musicFileURL.deletingPathExtension().appendingPathExtension("lrc")

        guard fileManager.fileExists(atPath: lrcURL.path) else {
            return
        }

        do {
            let destinationLrcURL: URL

            if preserveStructure, let baseURL = baseURL {
                // Preserve directory structure
                let relativePath = lrcURL.path.replacingOccurrences(of: baseURL.path, with: "")
                destinationLrcURL = musicDirectory.appendingPathComponent(relativePath)
            } else {
                // Flat import
                destinationLrcURL = musicDirectory.appendingPathComponent(lrcURL.lastPathComponent)
            }

            // Copy .lrc file if it doesn't exist
            if !fileManager.fileExists(atPath: destinationLrcURL.path) {
                try fileManager.copyItem(at: lrcURL, to: destinationLrcURL)
                print("✅ Imported lyrics: \(lrcURL.lastPathComponent)")
            }
        } catch {
            print("⚠️ Failed to import lyrics file: \(error.localizedDescription)")
        }
    }

    // MARK: - Extract Metadata
    /// Extract metadata from a music file
    /// Extracts: title, artist, album, artwork, duration, genre, year, track number, and lyrics
    /// Enhanced support for MP3 ID3 tags and other formats
    /// - Parameter file: The music file to extract metadata from
    /// - Returns: MusicMetadata object containing all extracted information
    func extractMetadata(from file: MusicFile) async -> MusicMetadata {
        let asset = AVAsset(url: file.url)
        var metadata = MusicMetadata()

        // Extract duration
        do {
            let duration = try await asset.load(.duration)
            metadata.duration = CMTimeGetSeconds(duration)
        } catch {
            print("⚠️ Error loading duration for \(file.name): \(error.localizedDescription)")
        }

        // Extract metadata from audio file
        do {
            // First, try common metadata (works for M4A, AAC, etc.)
            let commonMetadata = try await asset.load(.commonMetadata)

            for item in commonMetadata {
                guard let key = item.commonKey?.rawValue, let value = try await item.load(.value) else {
                    continue
                }

                switch key {
                case "title":
                    metadata.title = value as? String
                case "artist":
                    metadata.artist = value as? String
                case "albumName":
                    metadata.album = value as? String
                case "artwork":
                    if let data = value as? Data {
                        metadata.albumArtwork = UIImage(data: data)
                    }
                case "type":
                    metadata.genre = value as? String
                case "creationDate":
                    metadata.year = value as? String
                default:
                    break
                }
            }

            // For MP3 files, also check ID3 tags and format-specific metadata
            let allMetadata = try await asset.load(.metadata)

            for item in allMetadata {
                let keySpace = item.keySpace
                let key = item.key as? String

                // Handle ID3 tags (MP3 files)
                if keySpace == .id3 {
                    guard let value = try? await item.load(.value) else { continue }

                    switch key {
                    case "TIT2": // Title
                        if metadata.title == nil, let title = value as? String {
                            metadata.title = title
                        }
                    case "TPE1": // Artist
                        if metadata.artist == nil, let artist = value as? String {
                            metadata.artist = artist
                        }
                    case "TALB": // Album
                        if metadata.album == nil, let album = value as? String {
                            metadata.album = album
                        }
                    case "APIC": // Album artwork
                        if metadata.albumArtwork == nil, let data = value as? Data {
                            metadata.albumArtwork = UIImage(data: data)
                        }
                    case "TCON": // Genre
                        if metadata.genre == nil, let genre = value as? String {
                            metadata.genre = genre
                        }
                    case "TYER", "TDRC": // Year
                        if metadata.year == nil, let year = value as? String {
                            metadata.year = year
                        }
                    case "TRCK": // Track number
                        if metadata.trackNumber == nil {
                            if let trackStr = value as? String {
                                // Track number may be in format "3/12"
                                let trackNum = trackStr.split(separator: "/").first.flatMap { Int($0) }
                                metadata.trackNumber = trackNum
                            }
                        }
                    default:
                        break
                    }
                }

                // Handle iTunes metadata (M4A files)
                else if keySpace == .iTunes {
                    guard let value = try? await item.load(.value) else { continue }

                    switch key {
                    case "©nam": // Title
                        if metadata.title == nil, let title = value as? String {
                            metadata.title = title
                        }
                    case "©ART": // Artist
                        if metadata.artist == nil, let artist = value as? String {
                            metadata.artist = artist
                        }
                    case "©alb": // Album
                        if metadata.album == nil, let album = value as? String {
                            metadata.album = album
                        }
                    case "covr": // Cover art
                        if metadata.albumArtwork == nil, let data = value as? Data {
                            metadata.albumArtwork = UIImage(data: data)
                        }
                    case "©gen": // Genre
                        if metadata.genre == nil, let genre = value as? String {
                            metadata.genre = genre
                        }
                    case "©day": // Year
                        if metadata.year == nil, let year = value as? String {
                            metadata.year = year
                        }
                    case "trkn": // Track number
                        if metadata.trackNumber == nil {
                            if let data = value as? Data, data.count >= 4 {
                                // Track number is stored as binary data
                                let trackNum = Int(data[3])
                                metadata.trackNumber = trackNum
                            }
                        }
                    default:
                        break
                    }
                }

                // Handle QuickTime metadata (MOV, M4A)
                else if keySpace == .quickTimeMetadata {
                    guard let value = try? await item.load(.value) else { continue }

                    if let commonKey = item.commonKey {
                        switch commonKey {
                        case .commonKeyTitle:
                            if metadata.title == nil, let title = value as? String {
                                metadata.title = title
                            }
                        case .commonKeyArtist:
                            if metadata.artist == nil, let artist = value as? String {
                                metadata.artist = artist
                            }
                        case .commonKeyAlbumName:
                            if metadata.album == nil, let album = value as? String {
                                metadata.album = album
                            }
                        case .commonKeyArtwork:
                            if metadata.albumArtwork == nil, let data = value as? Data {
                                metadata.albumArtwork = UIImage(data: data)
                            }
                        default:
                            break
                        }
                    }
                }
            }

            // Additional artwork extraction attempt if still nil
            if metadata.albumArtwork == nil {
                for item in allMetadata {
                    if let dataValue = try? await item.load(.value) as? Data {
                        if let image = UIImage(data: dataValue) {
                            metadata.albumArtwork = image
                            break
                        }
                    }
                }
            }

        } catch {
            print("⚠️ Error loading metadata for \(file.name): \(error.localizedDescription)")
        }

        // Load lyrics (external .lrc file or embedded)
        if let lyrics = await lyricsService.loadLyrics(for: file) {
            metadata.lyrics = lyrics
            if lyrics.isSynced {
                print("✅ Loaded synced lyrics for: \(file.name)")
            } else if lyrics.hasLyrics {
                print("✅ Loaded plain lyrics for: \(file.name)")
            }
        }

        return metadata
    }

    // MARK: - Get Music Directory
    /// Get the root music directory URL
    /// - Returns: URL of the music directory
    func getMusicDirectory() -> URL {
        return musicDirectory
    }
}
