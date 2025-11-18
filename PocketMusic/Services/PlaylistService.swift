import Foundation
import Combine

// MARK: - Playlist Service
/// Service responsible for managing playlists
/// Handles:
/// - Creating, updating, and deleting playlists
/// - Persisting playlists to disk
/// - Loading playlists from disk
/// - Managing playlist tracks
class PlaylistService: ObservableObject {
    /// Shared singleton instance
    static let shared = PlaylistService()

    /// All user playlists
    @Published var playlists: [Playlist] = []

    /// File manager for disk operations
    private let fileManager = FileManager.default

    /// Playlists storage URL
    private let playlistsURL: URL

    /// Initialize the service and load playlists
    private init() {
        // Get documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.playlistsURL = documentsPath.appendingPathComponent("playlists.json")

        // Load playlists from disk
        loadPlaylists()
    }

    // MARK: - Playlist Management

    /// Create a new playlist
    /// - Parameter name: Name of the playlist
    /// - Returns: The created playlist
    @discardableResult
    func createPlaylist(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        savePlaylists()
        print("✅ Created playlist: \(name)")
        return playlist
    }

    /// Delete a playlist
    /// - Parameter playlist: The playlist to delete
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
        print("✅ Deleted playlist: \(playlist.name)")
    }

    /// Delete playlists at indices
    /// - Parameter indices: Indices of playlists to delete
    func deletePlaylists(at indices: IndexSet) {
        playlists.remove(atOffsets: indices)
        savePlaylists()
        print("✅ Deleted \(indices.count) playlist(s)")
    }

    /// Update a playlist
    /// - Parameter playlist: The updated playlist
    func updatePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            savePlaylists()
            print("✅ Updated playlist: \(playlist.name)")
        }
    }

    /// Rename a playlist
    /// - Parameters:
    ///   - playlist: The playlist to rename
    ///   - newName: The new name
    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].rename(to: newName)
            savePlaylists()
            print("✅ Renamed playlist to: \(newName)")
        }
    }

    // MARK: - Track Management

    /// Add a track to a playlist
    /// - Parameters:
    ///   - track: The track to add
    ///   - playlist: The playlist to add to
    func addTrack(_ track: MusicFile, to playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].addTrack(track)
            savePlaylists()
            print("✅ Added \(track.name) to \(playlist.name)")
        }
    }

    /// Add multiple tracks to a playlist
    /// - Parameters:
    ///   - tracks: The tracks to add
    ///   - playlist: The playlist to add to
    func addTracks(_ tracks: [MusicFile], to playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].addTracks(tracks)
            savePlaylists()
            print("✅ Added \(tracks.count) track(s) to \(playlist.name)")
        }
    }

    /// Remove a track from a playlist
    /// - Parameters:
    ///   - trackIndex: Index of the track to remove
    ///   - playlist: The playlist to remove from
    func removeTrack(at trackIndex: Int, from playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].removeTrack(at: trackIndex)
            savePlaylists()
            print("✅ Removed track from \(playlist.name)")
        }
    }

    /// Remove multiple tracks from a playlist
    /// - Parameters:
    ///   - indices: Indices of tracks to remove
    ///   - playlist: The playlist to remove from
    func removeTracks(at indices: IndexSet, from playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].removeTracks(at: indices)
            savePlaylists()
            print("✅ Removed \(indices.count) track(s) from \(playlist.name)")
        }
    }

    /// Move a track within a playlist
    /// - Parameters:
    ///   - source: Source index
    ///   - destination: Destination index
    ///   - playlist: The playlist
    func moveTrack(from source: Int, to destination: Int, in playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].moveTrack(from: source, to: destination)
            savePlaylists()
        }
    }

    // MARK: - Persistence

    /// Save playlists to disk
    private func savePlaylists() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(playlists)
            try data.write(to: playlistsURL)
            print("💾 Saved \(playlists.count) playlist(s)")
        } catch {
            print("❌ Failed to save playlists: \(error.localizedDescription)")
        }
    }

    /// Load playlists from disk
    private func loadPlaylists() {
        guard fileManager.fileExists(atPath: playlistsURL.path) else {
            print("ℹ️ No saved playlists found")
            return
        }

        do {
            let data = try Data(contentsOf: playlistsURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            playlists = try decoder.decode([Playlist].self, from: data)
            print("✅ Loaded \(playlists.count) playlist(s)")
        } catch {
            print("❌ Failed to load playlists: \(error.localizedDescription)")
        }
    }

    /// Get playlist by ID
    /// - Parameter id: Playlist ID
    /// - Returns: The playlist if found
    func getPlaylist(by id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }
}
