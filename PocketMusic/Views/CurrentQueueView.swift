import SwiftUI

// MARK: - Current Queue View
/// Displays and manages the current play queue
struct CurrentQueueView: View {
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: playerViewModel.backgroundColor),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(0.3)

                VStack(spacing: 0) {
                    // Queue info
                    queueInfoHeader

                    // Track list
                    if playerViewModel.playQueue.tracks.isEmpty {
                        emptyQueueView
                    } else {
                        trackList
                    }
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            playerViewModel.clearQueue()
                            dismiss()
                        } label: {
                            Label("Clear Queue", systemImage: "trash")
                        }

                        Button {
                            playerViewModel.toggleShuffle()
                        } label: {
                            Label(
                                playerViewModel.playQueue.shuffleEnabled ? "Shuffle Off" : "Shuffle On",
                                systemImage: "shuffle"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Queue Info Header
    private var queueInfoHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(playerViewModel.playQueue.tracks.count) tracks")
                        .font(.headline)
                    Text("Track \(playerViewModel.playQueue.currentIndex + 1) of \(playerViewModel.playQueue.tracks.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Playback controls
                HStack(spacing: 20) {
                    Button {
                        playerViewModel.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundColor(playerViewModel.playQueue.shuffleEnabled ? .accentColor : .secondary)
                            .font(.title3)
                    }

                    Button {
                        playerViewModel.toggleRepeatMode()
                    } label: {
                        Image(systemName: playerViewModel.playQueue.repeatMode.systemImage)
                            .foregroundColor(playerViewModel.playQueue.repeatMode == .off ? .secondary : .accentColor)
                            .font(.title3)
                    }
                }
            }
            .padding()

            Divider()
        }
        .background(.regularMaterial)
    }

    // MARK: - Track List
    private var trackList: some View {
        List {
            ForEach(Array(playerViewModel.playQueue.tracks.enumerated()), id: \.element.id) { index, track in
                QueueTrackRow(
                    track: track,
                    isPlaying: index == playerViewModel.playQueue.currentIndex,
                    index: index
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    playerViewModel.jumpToTrack(at: index)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        playerViewModel.removeFromQueue(at: index)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
                .listRowBackground(
                    index == playerViewModel.playQueue.currentIndex ?
                        Color.accentColor.opacity(0.2) : Color.clear
                )
            }
            .onMove { source, destination in
                playerViewModel.moveInQueue(from: source.first!, to: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty Queue View
    private var emptyQueueView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Queue is Empty")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add songs to start playing")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Queue Track Row
struct QueueTrackRow: View {
    let track: MusicFile
    let isPlaying: Bool
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Track number or playing indicator
            ZStack {
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 30)

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
                    .fontWeight(isPlaying ? .semibold : .regular)
                    .foregroundColor(isPlaying ? .accentColor : .primary)
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
            }

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.caption)
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
    CurrentQueueView()
        .environmentObject(PlayerViewModel())
}
