import Foundation
import Combine

// MARK: - Music Library ViewModel
@MainActor
class MusicLibraryViewModel: ObservableObject {
    @Published var library = MusicLibrary()
    @Published var currentFolder: Folder?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fileManager = FileManagerService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadLibrary()
    }

    // MARK: - Load Library
    func loadLibrary() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let musicDirectory = fileManager.getMusicDirectory()
                let rootFolder = fileManager.scanDirectory(at: musicDirectory)

                // Extract all files recursively
                var allFiles: [MusicFile] = []
                extractFiles(from: rootFolder, into: &allFiles)

                // Load metadata for all files
                for i in 0..<allFiles.count {
                    let metadata = await fileManager.extractMetadata(from: allFiles[i])
                    allFiles[i].metadata = metadata
                }

                await MainActor.run {
                    self.library = MusicLibrary(
                        folders: rootFolder.subfolders,
                        allFiles: allFiles
                    )
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func extractFiles(from folder: Folder, into array: inout [MusicFile]) {
        array.append(contentsOf: folder.musicFiles)
        for subfolder in folder.subfolders {
            extractFiles(from: subfolder, into: &array)
        }
    }

    // MARK: - Import Files
    func importFiles(from urls: [URL], preserveStructure: Bool = true) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let importedFiles = try await fileManager.importFiles(from: urls, preserveStructure: preserveStructure)

                // Load metadata for imported files
                var filesWithMetadata: [MusicFile] = []
                for var file in importedFiles {
                    let metadata = await fileManager.extractMetadata(from: file)
                    file.metadata = metadata
                    filesWithMetadata.append(file)
                }

                await MainActor.run {
                    // Reload library
                    self.loadLibrary()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "导入失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Navigation
    func navigateToFolder(_ folder: Folder) {
        currentFolder = folder
    }

    func navigateBack() {
        currentFolder = nil
    }

    // MARK: - Search
    func searchFiles(query: String) -> [MusicFile] {
        guard !query.isEmpty else { return library.allFiles }

        return library.allFiles.filter { file in
            let nameMatch = file.name.localizedCaseInsensitiveContains(query)
            let titleMatch = file.metadata?.title?.localizedCaseInsensitiveContains(query) ?? false
            let artistMatch = file.metadata?.artist?.localizedCaseInsensitiveContains(query) ?? false
            let albumMatch = file.metadata?.album?.localizedCaseInsensitiveContains(query) ?? false

            return nameMatch || titleMatch || artistMatch || albumMatch
        }
    }
}
