import Foundation
import AVFoundation
import Combine

// MARK: - Audio Player Service
class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying: Bool = false
    @Published var currentTrack: MusicFile?

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Playback Control
    func play(track: MusicFile) {
        // If it's the same track, just resume
        if currentTrack?.url == track.url {
            resume()
            return
        }

        // Stop current playback
        stop()

        // Create new player item
        currentTrack = track
        let asset = AVAsset(url: track.url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        // Add observers
        addObservers()

        // Start playback
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        removeObservers()
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    // MARK: - Observers
    private func addObservers() {
        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Duration observer
        playerItem?.publisher(for: \.duration)
            .sink { [weak self] duration in
                if duration.isNumeric {
                    self?.duration = duration.seconds
                }
            }
            .store(in: &cancellables)

        // End of track observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    private func removeObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        cancellables.removeAll()

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0
        // Post notification for playlist management
        NotificationCenter.default.post(name: .trackDidFinish, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let trackDidFinish = Notification.Name("trackDidFinish")
}
