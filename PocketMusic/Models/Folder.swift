import Foundation

// MARK: - Folder Model
struct Folder: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    var subfolders: [Folder]
    var musicFiles: [MusicFile]

    init(url: URL, subfolders: [Folder] = [], musicFiles: [MusicFile] = []) {
        self.url = url
        self.name = url.lastPathComponent
        self.subfolders = subfolders
        self.musicFiles = musicFiles
    }

    var isEmpty: Bool {
        subfolders.isEmpty && musicFiles.isEmpty
    }

    var totalFileCount: Int {
        musicFiles.count + subfolders.reduce(0) { $0 + $1.totalFileCount }
    }
}

// MARK: - Library Root
struct MusicLibrary {
    var folders: [Folder]
    var allFiles: [MusicFile]

    init() {
        self.folders = []
        self.allFiles = []
    }

    var totalFileCount: Int {
        allFiles.count
    }
}
