import Foundation

// MARK: - Play Queue Model
/// Represents the current play queue
/// Manages the list of tracks to be played and the current position
struct PlayQueue: Codable {
    var id = UUID()
    var tracks: [MusicFile]
    var currentIndex: Int
    var shuffleEnabled: Bool = false
    var repeatMode: RepeatMode = .off
    var originalOrder: [MusicFile]? // Store original order when shuffle is enabled

    init(tracks: [MusicFile] = [], currentIndex: Int = 0) {
        self.tracks = tracks
        self.currentIndex = currentIndex
    }

    /// Current playing track
    var currentTrack: MusicFile? {
        guard currentIndex >= 0 && currentIndex < tracks.count else {
            return nil
        }
        return tracks[currentIndex]
    }

    /// Check if there's a next track
    var hasNext: Bool {
        switch repeatMode {
        case .off:
            return currentIndex < tracks.count - 1
        case .all, .one:
            return !tracks.isEmpty
        }
    }

    /// Check if there's a previous track
    var hasPrevious: Bool {
        switch repeatMode {
        case .off:
            return currentIndex > 0
        case .all, .one:
            return !tracks.isEmpty
        }
    }

    /// Move to next track
    mutating func next() -> MusicFile? {
        guard hasNext else { return nil }

        switch repeatMode {
        case .off:
            currentIndex += 1
        case .all:
            currentIndex = (currentIndex + 1) % tracks.count
        case .one:
            // Stay on current track
            break
        }

        return currentTrack
    }

    /// Move to previous track
    mutating func previous() -> MusicFile? {
        guard hasPrevious else { return nil }

        switch repeatMode {
        case .off:
            currentIndex -= 1
        case .all:
            currentIndex = (currentIndex - 1 + tracks.count) % tracks.count
        case .one:
            // Stay on current track
            break
        }

        return currentTrack
    }

    /// Add track to the end of queue
    mutating func addTrack(_ track: MusicFile) {
        tracks.append(track)
    }

    /// Add tracks to the end of queue
    mutating func addTracks(_ newTracks: [MusicFile]) {
        tracks.append(contentsOf: newTracks)
    }

    /// Insert track after current position
    mutating func insertNext(_ track: MusicFile) {
        let insertIndex = currentIndex + 1
        if insertIndex <= tracks.count {
            tracks.insert(track, at: insertIndex)
        } else {
            tracks.append(track)
        }
    }

    /// Remove track at index
    mutating func removeTrack(at index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        tracks.remove(at: index)

        // Adjust current index if needed
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex && currentIndex >= tracks.count {
            currentIndex = max(0, tracks.count - 1)
        }
    }

    /// Move track from one position to another
    mutating func moveTrack(from source: Int, to destination: Int) {
        guard source >= 0 && source < tracks.count &&
              destination >= 0 && destination < tracks.count else {
            return
        }

        let track = tracks.remove(at: source)
        tracks.insert(track, at: destination)

        // Adjust current index
        if source == currentIndex {
            currentIndex = destination
        } else if source < currentIndex && destination >= currentIndex {
            currentIndex -= 1
        } else if source > currentIndex && destination <= currentIndex {
            currentIndex += 1
        }
    }

    /// Clear the queue
    mutating func clear() {
        tracks.removeAll()
        currentIndex = 0
        originalOrder = nil
    }

    /// Toggle shuffle
    mutating func toggleShuffle() {
        shuffleEnabled.toggle()

        if shuffleEnabled {
            // Save original order
            originalOrder = tracks

            // Get current track before shuffle
            let current = currentTrack

            // Shuffle tracks
            var shuffled = tracks
            shuffled.shuffle()

            // Ensure current track stays at current position
            if let current = current,
               let currentIndexInShuffled = shuffled.firstIndex(where: { $0.id == current.id }) {
                shuffled.swapAt(currentIndex, currentIndexInShuffled)
            }

            tracks = shuffled
        } else {
            // Restore original order
            if let original = originalOrder {
                let current = currentTrack
                tracks = original

                // Find current track in original order
                if let current = current,
                   let newIndex = tracks.firstIndex(where: { $0.id == current.id }) {
                    currentIndex = newIndex
                }
            }
            originalOrder = nil
        }
    }

    /// Set repeat mode
    mutating func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
    }

    /// Jump to specific track
    mutating func jumpTo(index: Int) {
        guard index >= 0 && index < tracks.count else { return }
        currentIndex = index
    }
}

// MARK: - Repeat Mode
enum RepeatMode: String, Codable, CaseIterable {
    case off = "Off"
    case all = "All"
    case one = "One"

    var systemImage: String {
        switch self {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    func next() -> RepeatMode {
        switch self {
        case .off:
            return .all
        case .all:
            return .one
        case .one:
            return .off
        }
    }
}
