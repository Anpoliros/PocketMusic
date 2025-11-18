import Foundation
import Combine
import SwiftUI

// MARK: - Player ViewModel
@MainActor
class PlayerViewModel: ObservableObject {
    @Published var playerState = PlayerState()
    @Published var playlist: [MusicFile] = []
    @Published var currentIndex: Int = 0
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
            self.playlist = playlist
            if let index = playlist.firstIndex(where: { $0.id == track.id }) {
                currentIndex = index
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
        guard !playlist.isEmpty else { return }

        switch playerState.repeatMode {
        case .one:
            // Replay current track
            if let track = playerState.currentTrack {
                audioPlayer.play(track: track)
            }
        case .all:
            // Move to next track, loop to beginning if at end
            currentIndex = (currentIndex + 1) % playlist.count
            audioPlayer.play(track: playlist[currentIndex])
        case .off:
            // Move to next track if available
            if currentIndex < playlist.count - 1 {
                currentIndex += 1
                audioPlayer.play(track: playlist[currentIndex])
            } else {
                stop()
            }
        }
    }

    func playPrevious() {
        guard !playlist.isEmpty else { return }

        // If more than 3 seconds into the track, restart it
        if playerState.currentTime > 3.0 {
            seek(to: 0)
            return
        }

        // Otherwise go to previous track
        if currentIndex > 0 {
            currentIndex -= 1
        } else if playerState.repeatMode == .all {
            currentIndex = playlist.count - 1
        }

        audioPlayer.play(track: playlist[currentIndex])
    }

    // MARK: - Playback Modes
    func toggleRepeatMode() {
        switch playerState.repeatMode {
        case .off:
            playerState.repeatMode = .all
        case .all:
            playerState.repeatMode = .one
        case .one:
            playerState.repeatMode = .off
        }
    }

    func toggleShuffle() {
        playerState.shuffleEnabled.toggle()

        if playerState.shuffleEnabled {
            // Shuffle playlist, keeping current track at current position
            if let currentTrack = playerState.currentTrack,
               let originalIndex = playlist.firstIndex(where: { $0.id == currentTrack.id }) {
                var shuffled = playlist
                shuffled.remove(at: originalIndex)
                shuffled.shuffle()
                shuffled.insert(currentTrack, at: currentIndex)
                playlist = shuffled
            }
        }
    }

    // MARK: - Helpers
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
