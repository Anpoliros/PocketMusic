import Foundation
import AVFoundation
import Combine

// MARK: - Audio Player Service
/// Service responsible for audio playback using AVFoundation
/// Handles:
/// - Playing audio files
/// - Playback control (play, pause, seek)
/// - Tracking playback time and duration
/// - Volume control
/// - Notifying when tracks finish playing
///
/// Design:
/// - Singleton pattern for global access
/// - Uses Combine for reactive state updates
/// - Decoupled from UI and business logic
class AudioPlayerService: NSObject, ObservableObject {
    /// Shared singleton instance
    static let shared = AudioPlayerService()

    // MARK: - Private Properties
    /// AVPlayer instance for audio playback
    private var player: AVPlayer?

    /// Current player item being played
    private var playerItem: AVPlayerItem?

    /// Observer for periodic time updates
    private var timeObserver: Any?

    /// Set of Combine cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties
    /// Current playback time in seconds
    @Published var currentTime: TimeInterval = 0

    /// Total duration of current track in seconds
    @Published var duration: TimeInterval = 0

    /// Whether audio is currently playing
    @Published var isPlaying: Bool = false

    /// Currently loaded track
    @Published var currentTrack: MusicFile?

    // MARK: - Initialization
    /// Private initializer to enforce singleton pattern
    override init() {
        super.init()
        setupAudioSession()
    }

    /// Configure audio session for background playback
    /// Sets category to .playback to allow audio to play when app is in background
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Set category to .playback for background audio support
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Playback Control
    /// Play a music track
    /// If the same track is already loaded, resumes playback instead of reloading
    /// - Parameter track: The MusicFile to play
    func play(track: MusicFile) {
        // Optimization: If same track is already loaded, just resume
        if currentTrack?.url == track.url, player != nil {
            resume()
            return
        }

        // Stop and clean up current playback
        stop()

        // Load new track
        currentTrack = track
        let asset = AVAsset(url: track.url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        // Set up observers for time tracking and completion
        addObservers()

        // Start playback
        player?.play()
        isPlaying = true

        print("▶️ Playing: \(track.name)")
    }

    /// Pause current playback
    /// Playback position is preserved
    func pause() {
        player?.pause()
        isPlaying = false
        print("⏸ Paused")
    }

    /// Resume playback from current position
    func resume() {
        player?.play()
        isPlaying = true
        print("▶️ Resumed")
    }

    /// Stop playback and release player resources
    /// Resets playback position and removes all observers
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        removeObservers()
        isPlaying = false
        currentTime = 0
        duration = 0
        print("⏹ Stopped")
    }

    /// Seek to a specific time position
    /// - Parameter time: Target time in seconds
    func seek(to time: TimeInterval) {
        // Use preferredTimescale of 600 for precise seeking
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        print("⏩ Seeked to: \(time)s")
    }

    /// Set playback volume
    /// - Parameter volume: Volume level from 0.0 (silent) to 1.0 (maximum)
    func setVolume(_ volume: Float) {
        let clampedVolume = max(0.0, min(1.0, volume))
        player?.volume = clampedVolume
    }

    // MARK: - Observers
    /// Add observers for playback time, duration, and completion
    /// Sets up:
    /// 1. Periodic time observer (updates every 0.5 seconds)
    /// 2. Duration observer (tracks total track length)
    /// 3. Completion observer (notifies when track finishes)
    private func addObservers() {
        // Periodic time observer - updates current playback time
        // Update interval: 0.5 seconds (500ms)
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Duration observer - tracks when duration becomes available
        // Duration may not be immediately available for some formats
        playerItem?.publisher(for: \.duration)
            .sink { [weak self] duration in
                if duration.isNumeric {
                    self?.duration = duration.seconds
                }
            }
            .store(in: &cancellables)

        // Track completion observer - notifies when playback finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    /// Remove all observers and clean up subscriptions
    /// Called when stopping playback or loading a new track
    private func removeObservers() {
        // Remove periodic time observer
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // Cancel all Combine subscriptions
        cancellables.removeAll()

        // Remove NotificationCenter observer
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    /// Called when current track finishes playing
    /// Posts notification to allow playlist management (auto-play next track)
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0

        // Post notification for PlayerViewModel to handle (e.g., play next track)
        NotificationCenter.default.post(name: .trackDidFinish, object: nil)

        print("✅ Track finished playing")
    }
}

// MARK: - Notification Names
/// Custom notification names for audio playback events
extension Notification.Name {
    /// Posted when a track finishes playing
    /// Used by PlayerViewModel to automatically play the next track in playlist
    static let trackDidFinish = Notification.Name("trackDidFinish")
}
