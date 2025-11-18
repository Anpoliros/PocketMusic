import Foundation
import AVFoundation
import UIKit

// MARK: - File Manager Service
class FileManagerService: ObservableObject {
    static let shared = FileManagerService()

    private let fileManager = FileManager.default
    private let musicDirectory: URL

    init() {
        // Create a dedicated music directory in the app's documents folder
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.musicDirectory = documentsPath.appendingPathComponent("Music", isDirectory: true)

        // Create directory if it doesn't exist
        createMusicDirectoryIfNeeded()
    }

    private func createMusicDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: musicDirectory.path) {
            try? fileManager.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Scan Directory
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
    func importFiles(from sourceURLs: [URL], preserveStructure: Bool = true) async throws -> [MusicFile] {
        var importedFiles: [MusicFile] = []

        for sourceURL in sourceURLs {
            // Start accessing security-scoped resource
            guard sourceURL.startAccessingSecurityScopedResource() else {
                continue
            }

            defer { sourceURL.stopAccessingSecurityScopedResource() }

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory)

            if isDirectory.boolValue {
                // Import entire directory
                let files = try await importDirectory(from: sourceURL, preserveStructure: preserveStructure)
                importedFiles.append(contentsOf: files)
            } else {
                // Import single file
                if let file = try await importFile(from: sourceURL) {
                    importedFiles.append(file)
                }
            }
        }

        return importedFiles
    }

    private func importDirectory(from sourceURL: URL, preserveStructure: Bool) async throws -> [MusicFile] {
        var importedFiles: [MusicFile] = []

        let enumerator = fileManager.enumerator(at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey])

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])

            if resourceValues.isDirectory == false {
                let musicFile = MusicFile(url: fileURL)
                if musicFile.isSupported {
                    if let importedFile = try await importFile(from: fileURL, preserveStructure: preserveStructure, baseURL: sourceURL) {
                        importedFiles.append(importedFile)
                    }
                }
            }
        }

        return importedFiles
    }

    private func importFile(from sourceURL: URL, preserveStructure: Bool = true, baseURL: URL? = nil) async throws -> MusicFile? {
        let musicFile = MusicFile(url: sourceURL)
        guard musicFile.isSupported else { return nil }

        let destinationURL: URL

        if preserveStructure, let baseURL = baseURL {
            // Preserve directory structure
            let relativePath = sourceURL.path.replacingOccurrences(of: baseURL.path, with: "")
            destinationURL = musicDirectory.appendingPathComponent(relativePath)

            // Create intermediate directories
            let destinationDirectory = destinationURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        } else {
            // Flat import
            destinationURL = musicDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        }

        // Copy file if it doesn't exist
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        return MusicFile(url: destinationURL)
    }

    // MARK: - Extract Metadata
    func extractMetadata(from file: MusicFile) async -> MusicMetadata {
        let asset = AVAsset(url: file.url)
        var metadata = MusicMetadata()

        // Extract duration
        do {
            let duration = try await asset.load(.duration)
            metadata.duration = CMTimeGetSeconds(duration)
        } catch {
            print("Error loading duration: \(error)")
        }

        // Extract metadata
        do {
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
        } catch {
            print("Error loading metadata: \(error)")
        }

        return metadata
    }

    // MARK: - Get Music Directory
    func getMusicDirectory() -> URL {
        return musicDirectory
    }
}
