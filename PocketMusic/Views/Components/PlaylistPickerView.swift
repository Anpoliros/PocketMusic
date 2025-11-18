import SwiftUI

// MARK: - Playlist Picker View
/// View for selecting a playlist to add a track to
struct PlaylistPickerView: View {
    let track: MusicFile?
    @StateObject private var playlistService = PlaylistService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""

    var body: some View {
        NavigationView {
            List {
                // Create new playlist option
                Button {
                    showingCreatePlaylist = true
                } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor.gradient)
                                .frame(width: 50, height: 50)

                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        Text("创建新播放列表")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }

                // Existing playlists
                if !playlistService.playlists.isEmpty {
                    Section("现有播放列表") {
                        ForEach(playlistService.playlists) { playlist in
                            Button {
                                addToPlaylist(playlist)
                            } label: {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 50, height: 50)

                                        Image(systemName: "music.note.list")
                                            .font(.title3)
                                            .foregroundColor(.accentColor)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(playlist.name)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        Text("\(playlist.trackCount) 首歌曲")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Check mark if track is already in playlist
                                    if let track = track, playlist.contains(track) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加到播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("创建播放列表", isPresented: $showingCreatePlaylist) {
                TextField("播放列表名称", text: $newPlaylistName)
                Button("取消", role: .cancel) {
                    newPlaylistName = ""
                }
                Button("创建") {
                    createAndAddToPlaylist()
                }
            }
        }
    }

    // MARK: - Actions
    private func addToPlaylist(_ playlist: Playlist) {
        guard let track = track else { return }

        if playlist.contains(track) {
            // Track already in playlist, optionally show alert
            return
        }

        playlistService.addTrack(track, to: playlist)
        dismiss()
    }

    private func createAndAddToPlaylist() {
        guard !newPlaylistName.isEmpty else { return }
        let newPlaylist = playlistService.createPlaylist(name: newPlaylistName)

        if let track = track {
            playlistService.addTrack(track, to: newPlaylist)
        }

        newPlaylistName = ""
        dismiss()
    }
}

#Preview {
    PlaylistPickerView(track: nil)
}
