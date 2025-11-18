import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var isDraggingSlider = false
    @State private var sliderValue: Double = 0

    var body: some View {
        ZStack {
            // Dynamic background
            DynamicBackgroundView(colors: playerViewModel.backgroundColor)
                .animation(.easeInOut(duration: 1.0), value: playerViewModel.backgroundColor)

            // Content
            VStack {
                if let track = playerViewModel.playerState.currentTrack {
                    ScrollView {
                        VStack(spacing: 30) {
                            Spacer()
                                .frame(height: 20)

                            // Album artwork
                            albumArtwork(track: track)
                                .padding(.horizontal, 40)

                            // Track info
                            trackInfo(track: track)
                                .padding(.horizontal, 30)

                            // Progress bar
                            progressBar

                            // Playback controls
                            playbackControls
                                .padding(.horizontal, 30)

                            // Volume control
                            volumeControl
                                .padding(.horizontal, 40)

                            Spacer()
                        }
                    }
                } else {
                    // Empty state
                    emptyState
                }
            }
        }
        .navigationTitle("正在播放")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Album Artwork
    private func albumArtwork(track: MusicFile) -> some View {
        Group {
            if let artwork = track.metadata?.albumArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 300)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
    }

    // MARK: - Track Info
    private func trackInfo(track: MusicFile) -> some View {
        VStack(spacing: 8) {
            Text(track.metadata?.displayTitle ?? track.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(track.metadata?.displayArtist ?? "Unknown Artist")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)

            if let album = track.metadata?.album {
                Text(album)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: {
                        isDraggingSlider ? sliderValue : playerViewModel.playerState.currentTime
                    },
                    set: { newValue in
                        sliderValue = newValue
                    }
                ),
                in: 0...max(playerViewModel.playerState.duration, 1),
                onEditingChanged: { editing in
                    isDraggingSlider = editing
                    if !editing {
                        playerViewModel.seek(to: sliderValue)
                    }
                }
            )
            .tint(.white)

            HStack {
                Text(playerViewModel.formatTime(playerViewModel.playerState.currentTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()

                Spacer()

                Text(playerViewModel.formatTime(playerViewModel.playerState.duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Shuffle
            Button {
                playerViewModel.toggleShuffle()
            } label: {
                Image(systemName: playerViewModel.playerState.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // Previous
            Button {
                playerViewModel.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }

            // Play/Pause
            Button {
                playerViewModel.togglePlayPause()
            } label: {
                Image(systemName: playerViewModel.playerState.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            // Next
            Button {
                playerViewModel.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }

            // Repeat
            Button {
                playerViewModel.toggleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
    }

    private var repeatIcon: String {
        switch playerViewModel.playerState.repeatMode {
        case .off:
            return "repeat"
        case .all:
            return "repeat.circle.fill"
        case .one:
            return "repeat.1.circle.fill"
        }
    }

    // MARK: - Volume Control
    private var volumeControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)

            Slider(
                value: Binding(
                    get: { playerViewModel.playerState.volume },
                    set: { playerViewModel.setVolume($0) }
                ),
                in: 0...1
            )
            .tint(.white)

            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))

            Text("没有正在播放的音乐")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            Text("从音乐库中选择一首歌曲开始播放")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationView {
        PlayerView()
    }
    .environmentObject(PlayerViewModel())
}
