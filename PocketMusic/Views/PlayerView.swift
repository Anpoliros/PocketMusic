import SwiftUI

// MARK: - Player View
/// Main player view mimicking Apple Music's design
/// Features:
/// - Album artwork display
/// - Synchronized lyrics view
/// - Playback controls
/// - Dynamic background based on album artwork
struct PlayerView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel

    // MARK: - State Properties
    @State private var isDraggingSlider = false
    @State private var sliderValue: Double = 0
    @State private var showLyrics = false

    var body: some View {
        ZStack {
            // Dynamic background with smooth color transitions
            DynamicBackgroundView(colors: playerViewModel.backgroundColor)
                .animation(.easeInOut(duration: 1.0), value: playerViewModel.backgroundColor)

            // Main content
            if let track = playerViewModel.playerState.currentTrack {
                playerContentView(track: track)
            } else {
                // Empty state when no track is playing
                emptyState
            }
        }
        .navigationTitle("正在播放")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Player Content View
    /// Main player content when a track is playing
    private func playerContentView(track: MusicFile) -> some View {
        VStack(spacing: 0) {
            // Top section: Artwork or Lyrics
            GeometryReader { geometry in
                if showLyrics, let lyrics = track.metadata?.lyrics, lyrics.hasLyrics {
                    // Lyrics view
                    LyricsView(
                        lyrics: lyrics,
                        currentTime: playerViewModel.playerState.currentTime
                    )
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Album artwork and track info
                    artworkAndInfoView(track: track, geometry: geometry)
                        .transition(.opacity.combined(with: .scale))
                }
            }

            // Bottom section: Controls
            controlsSection(track: track)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Artwork and Info View
    /// Album artwork and track information section
    private func artworkAndInfoView(track: MusicFile, geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // Album artwork
            albumArtwork(track: track, size: geometry.size)
                .padding(.horizontal, 40)

            // Track metadata
            trackInfo(track: track)
                .padding(.horizontal, 30)

            Spacer()
        }
    }

    // MARK: - Album Artwork
    /// Display album artwork or placeholder
    private func albumArtwork(track: MusicFile, size: CGSize) -> some View {
        let artworkSize = min(size.width - 80, size.height * 0.6, 400)

        return Group {
            if let artwork = track.metadata?.albumArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: artworkSize, height: artworkSize)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: artworkSize, height: artworkSize)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: artworkSize * 0.3))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
        .onTapGesture {
            // Toggle between artwork and lyrics view
            if track.metadata?.lyrics?.hasLyrics == true {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showLyrics.toggle()
                }
            }
        }
    }

    // MARK: - Track Info
    /// Display track title, artist, and album
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

            // Lyrics indicator
            if track.metadata?.lyrics?.hasLyrics == true {
                HStack(spacing: 4) {
                    Image(systemName: "text.quote")
                        .font(.caption2)
                    Text("点击封面查看歌词")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Controls Section
    /// Bottom section containing all playback controls
    private func controlsSection(track: MusicFile) -> some View {
        VStack(spacing: 20) {
            // Lyrics toggle button (only show if lyrics available)
            if track.metadata?.lyrics?.hasLyrics == true {
                lyricsToggleButton
            }

            // Progress bar
            progressBar
                .padding(.horizontal, 30)

            // Playback controls
            playbackControls
                .padding(.horizontal, 30)

            // Volume control
            volumeControl
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Lyrics Toggle Button
    /// Button to toggle between artwork and lyrics view
    private var lyricsToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showLyrics.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showLyrics ? "photo" : "text.quote")
                    .font(.subheadline)
                Text(showLyrics ? "专辑封面" : "显示歌词")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
        }
    }

    // MARK: - Progress Bar
    /// Playback progress slider with time labels
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
    }

    // MARK: - Playback Controls
    /// Main playback control buttons
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Shuffle button
            Button {
                playerViewModel.toggleShuffle()
            } label: {
                Image(systemName: playerViewModel.playerState.shuffleEnabled ? "shuffle.circle.fill" : "shuffle")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // Previous track button
            Button {
                playerViewModel.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }

            // Play/Pause button
            Button {
                playerViewModel.togglePlayPause()
            } label: {
                Image(systemName: playerViewModel.playerState.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            // Next track button
            Button {
                playerViewModel.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }

            // Repeat button
            Button {
                playerViewModel.toggleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
    }

    /// Icon for repeat button based on current repeat mode
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
    /// Volume slider with speaker icons
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
    /// Display when no track is currently playing
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

// MARK: - Preview
#Preview {
    NavigationView {
        PlayerView()
    }
    .environmentObject(PlayerViewModel())
}
