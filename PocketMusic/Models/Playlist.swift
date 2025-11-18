import Foundation

// MARK: - Playlist Model
/// Represents a user-created playlist
struct Playlist: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var tracks: [MusicFile]
    var createdAt: Date
    var modifiedAt: Date

    init(name: String, tracks: [MusicFile] = []) {
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    /// Number of tracks in playlist
    var trackCount: Int {
        tracks.count
    }

    /// Total duration of all tracks in seconds
    var totalDuration: TimeInterval {
        tracks.compactMap { $0.metadata?.duration }.reduce(0, +)
    }

    /// Formatted total duration string (e.g., "1:23:45")
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Add a track to the playlist
    mutating func addTrack(_ track: MusicFile) {
        tracks.append(track)
        modifiedAt = Date()
    }

    /// Add multiple tracks to the playlist
    mutating func addTracks(_ newTracks: [MusicFile]) {
        tracks.append(contentsOf: newTracks)
        modifiedAt = Date()
    }

    /// Remove track at index
    mutating func removeTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        tracks.remove(at: index)
        modifiedAt = Date()
    }

    /// Remove multiple tracks
    mutating func removeTracks(at indices: IndexSet) {
        tracks.remove(atOffsets: indices)
        modifiedAt = Date()
    }

    /// Move track from one position to another
    mutating func moveTrack(from source: Int, to destination: Int) {
        guard source >= 0 && source < tracks.count &&
              destination >= 0 && destination < tracks.count else {
            return
        }

        let track = tracks.remove(at: source)
        tracks.insert(track, at: destination)
        modifiedAt = Date()
    }

    /// Check if playlist contains a specific track
    func contains(_ track: MusicFile) -> Bool {
        tracks.contains(where: { $0.id == track.id })
    }

    /// Update playlist name
    mutating func rename(to newName: String) {
        name = newName
        modifiedAt = Date()
    }
}
