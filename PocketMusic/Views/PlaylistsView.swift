import SwiftUI

// MARK: - Playlists View
/// Main view for managing playlists
struct PlaylistsView: View {
    @StateObject private var playlistService = PlaylistService.shared
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""

    var body: some View {
        NavigationView {
            ZStack {
                if playlistService.playlists.isEmpty {
                    emptyState
                } else {
                    playlistList
                }
            }
            .navigationTitle("播放列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePlaylist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("创建播放列表", isPresented: $showingCreatePlaylist) {
                TextField("播放列表名称", text: $newPlaylistName)
                Button("取消", role: .cancel) {
                    newPlaylistName = ""
                }
                Button("创建") {
                    createPlaylist()
                }
            }
        }
    }

    // MARK: - Playlist List
    private var playlistList: some View {
        List {
            ForEach(playlistService.playlists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistRow(playlist: playlist)
                }
            }
            .onDelete { indexSet in
                playlistService.deletePlaylists(at: indexSet)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无播放列表")
                .font(.title2)
                .fontWeight(.semibold)

            Text("点击右上角 + 创建新的播放列表")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions
    private func createPlaylist() {
        guard !newPlaylistName.isEmpty else { return }
        playlistService.createPlaylist(name: newPlaylistName)
        newPlaylistName = ""
    }
}

// MARK: - Playlist Row
struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            // Playlist icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.gradient)
                    .frame(width: 60, height: 60)

                Image(systemName: "music.note.list")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(playlist.trackCount) 首歌曲")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if playlist.trackCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text(playlist.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PlaylistsView()
        .environmentObject(PlayerViewModel())
}
