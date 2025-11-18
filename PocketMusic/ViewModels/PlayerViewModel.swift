import Foundation
import Combine
import SwiftUI

// MARK: - Player ViewModel
@MainActor
class PlayerViewModel: ObservableObject {
    @Published var playerState = PlayerState()
    @Published var playQueue = PlayQueue()
    @Published var backgroundColor: [Color] = [.blue, .purple]

    private let audioPlayer = AudioPlayerService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
        setupNotifications()
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observe audio player state
        audioPlayer.$currentTime
            .sink { [weak self] time in
                self?.playerState.currentTime = time
            }
            .store(in: &cancellables)

        audioPlayer.$duration
            .sink { [weak self] duration in
                self?.playerState.duration = duration
            }
            .store(in: &cancellables)

        audioPlayer.$isPlaying
            .sink { [weak self] isPlaying in
                self?.playerState.playbackState = isPlaying ? .playing : .paused
            }
            .store(in: &cancellables)

        audioPlayer.$currentTrack
            .sink { [weak self] track in
                guard let self = self, let track = track else { return }
                self.playerState.currentTrack = track

                // Extract colors from artwork
                if let artwork = track.metadata?.albumArtwork {
                    let colors = ColorExtractorService.shared.extractColors(from: artwork)
                    self.backgroundColor = colors
                }
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackDidFinish),
            name: .trackDidFinish,
            object: nil
        )
    }

    @objc private func trackDidFinish() {
        Task { @MainActor in
            playNext()
        }
    }

    // MARK: - Playback Control
    func play(track: MusicFile, from playlist: [MusicFile] = []) {
        if !playlist.isEmpty {
            playQueue.tracks = playlist
            if let index = playlist.firstIndex(where: { $0.id == track.id }) {
                playQueue.currentIndex = index
            }
        }

        audioPlayer.play(track: track)
        playerState.playbackState = .playing
        playerState.currentTrack = track
    }

    func togglePlayPause() {
        if playerState.playbackState == .playing {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        audioPlayer.pause()
        playerState.playbackState = .paused
    }

    func resume() {
        if let track = playerState.currentTrack {
            audioPlayer.play(track: track)
        }
    }

    func stop() {
        audioPlayer.stop()
        playerState.playbackState = .stopped
        playerState.currentTrack = nil
        playerState.currentTime = 0
    }

    func seek(to time: TimeInterval) {
        audioPlayer.seek(to: time)
        playerState.currentTime = time
    }

    func setVolume(_ volume: Float) {
        audioPlayer.setVolume(volume)
        playerState.volume = volume
    }

    // MARK: - Playlist Navigation
    func playNext() {
        guard !playQueue.tracks.isEmpty else { return }

        if let nextTrack = playQueue.next() {
            audioPlayer.play(track: nextTrack)
        } else {
            stop()
        }
    }

    func playPrevious() {
        guard !playQueue.tracks.isEmpty else { return }

        // If more than 3 seconds into the track, restart it
        if playerState.currentTime > 3.0 {
            seek(to: 0)
            return
        }

        // Otherwise go to previous track
        if let previousTrack = playQueue.previous() {
            audioPlayer.play(track: previousTrack)
        }
    }

    // MARK: - Playback Modes
    func toggleRepeatMode() {
        let newMode = playQueue.repeatMode.next()
        playQueue.setRepeatMode(newMode)
        playerState.repeatMode = newMode
    }

    func toggleShuffle() {
        playQueue.toggleShuffle()
        playerState.shuffleEnabled = playQueue.shuffleEnabled
    }

    // MARK: - Queue Management
    func addToQueue(_ track: MusicFile) {
        playQueue.addTrack(track)
    }

    func addToQueue(_ tracks: [MusicFile]) {
        playQueue.addTracks(tracks)
    }

    func insertNext(_ track: MusicFile) {
        playQueue.insertNext(track)
    }

    func removeFromQueue(at index: Int) {
        playQueue.removeTrack(at: index)
    }

    func moveInQueue(from source: Int, to destination: Int) {
        playQueue.moveTrack(from: source, to: destination)
    }

    func jumpToTrack(at index: Int) {
        playQueue.jumpTo(index: index)
        if let track = playQueue.currentTrack {
            audioPlayer.play(track: track)
        }
    }

    func clearQueue() {
        playQueue.clear()
        stop()
    }

    // MARK: - Helpers
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
