import Foundation

// MARK: - Playback State
enum PlaybackState {
    case stopped
    case playing
    case paused
    case loading
}

// MARK: - Repeat Mode
enum RepeatMode {
    case off
    case one
    case all
}

// MARK: - Player State
struct PlayerState {
    var currentTrack: MusicFile?
    var playbackState: PlaybackState = .stopped
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var repeatMode: RepeatMode = .off
    var shuffleEnabled: Bool = false
    var volume: Float = 0.7

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}
