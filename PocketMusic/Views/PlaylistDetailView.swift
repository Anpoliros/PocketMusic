import SwiftUI

// MARK: - Playlist Detail View
/// Detailed view of a single playlist
struct PlaylistDetailView: View {
    let playlist: Playlist
    @StateObject private var playlistService = PlaylistService.shared
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showingRename = false
    @State private var newName = ""
    @State private var showingAddTracks = false

    var body: some View {
        List {
            // Header section
            Section {
                playlistHeader
            }

            // Tracks section
            Section {
                if currentPlaylist?.tracks.isEmpty ?? true {
                    emptyTracksView
                } else {
                    tracksList
                }
            } header: {
                HStack {
                    Text("歌曲")
                    Spacer()
                    if let count = currentPlaylist?.trackCount, count > 0 {
                        Text("\(count) 首")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(currentPlaylist?.name ?? playlist.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingRename = true
                        newName = currentPlaylist?.name ?? playlist.name
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }

                    Button {
                        playAllTracks()
                    } label: {
                        Label("播放全部", systemImage: "play.fill")
                    }
                    .disabled(currentPlaylist?.tracks.isEmpty ?? true)

                    Button {
                        shuffleAndPlay()
                    } label: {
                        Label("随机播放", systemImage: "shuffle")
                    }
                    .disabled(currentPlaylist?.tracks.isEmpty ?? true)

                    Divider()

                    Button(role: .destructive) {
                        deletePlaylist()
                    } label: {
                        Label("删除播放列表", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("重命名播放列表", isPresented: $showingRename) {
            TextField("播放列表名称", text: $newName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                renamePlaylist()
            }
        }
    }

    // MARK: - Current Playlist
    /// Get current playlist from service (handles updates)
    private var currentPlaylist: Playlist? {
        playlistService.getPlaylist(by: playlist.id)
    }

    // MARK: - Playlist Header
    private var playlistHeader: some View {
        VStack(spacing: 12) {
            // Playlist icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.gradient)
                    .frame(width: 120, height: 120)

                Image(systemName: "music.note.list")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // Playlist info
            VStack(spacing: 4) {
                Text(currentPlaylist?.name ?? playlist.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let count = currentPlaylist?.trackCount, count > 0 {
                    HStack(spacing: 8) {
                        Text("\(count) 首歌曲")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(currentPlaylist?.formattedDuration ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 20) {
                Button {
                    playAllTracks()
                } label: {
                    Label("播放", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentPlaylist?.tracks.isEmpty ?? true)

                Button {
                    shuffleAndPlay()
                } label: {
                    Label("随机", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(currentPlaylist?.tracks.isEmpty ?? true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    // MARK: - Tracks List
    private var tracksList: some View {
        ForEach(Array((currentPlaylist?.tracks ?? []).enumerated()), id: \.element.id) { index, track in
            Button {
                playTrack(track, at: index)
            } label: {
                PlaylistTrackRow(track: track, index: index)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    removeTrack(at: index)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .onMove { source, destination in
            moveTrack(from: source, to: destination)
        }
    }

    // MARK: - Empty Tracks View
    private var emptyTracksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("此播放列表还没有歌曲")
                .font(.body)
                .foregroundColor(.secondary)

            Text("从音乐库中选择歌曲并添加到此播放列表")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions
    private func playAllTracks() {
        guard let tracks = currentPlaylist?.tracks, !tracks.isEmpty else { return }
        playerViewModel.play(track: tracks[0], from: tracks)
    }

    private func shuffleAndPlay() {
        guard var tracks = currentPlaylist?.tracks, !tracks.isEmpty else { return }
        tracks.shuffle()
        playerViewModel.play(track: tracks[0], from: tracks)
    }

    private func playTrack(_ track: MusicFile, at index: Int) {
        guard let tracks = currentPlaylist?.tracks else { return }
        playerViewModel.play(track: track, from: tracks)
    }

    private func removeTrack(at index: Int) {
        playlistService.removeTrack(at: index, from: playlist)
    }

    private func moveTrack(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }
        playlistService.moveTrack(from: sourceIndex, to: destination, in: playlist)
    }

    private func renamePlaylist() {
        guard !newName.isEmpty else { return }
        playlistService.renamePlaylist(playlist, to: newName)
    }

    private func deletePlaylist() {
        playlistService.deletePlaylist(playlist)
    }
}

// MARK: - Playlist Track Row
struct PlaylistTrackRow: View {
    let track: MusicFile
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Track number
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            // Album artwork
            if let artwork = track.metadata?.albumArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    }
            }

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.metadata?.displayTitle ?? track.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let artist = track.metadata?.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Duration
            if let duration = track.metadata?.duration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        PlaylistDetailView(playlist: Playlist(name: "我的最爱"))
    }
    .environmentObject(PlayerViewModel())
}
