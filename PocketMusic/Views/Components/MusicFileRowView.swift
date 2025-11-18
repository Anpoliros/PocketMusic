import SwiftUI

struct MusicFileRowView: View {
    let file: MusicFile
    @EnvironmentObject var playerViewModel: PlayerViewModel

    var isCurrentTrack: Bool {
        playerViewModel.playerState.currentTrack?.id == file.id
    }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork or placeholder
            if let artwork = file.metadata?.albumArtwork {
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
                Text(file.metadata?.displayTitle ?? file.displayName)
                    .font(.body)
                    .foregroundColor(isCurrentTrack ? .accentColor : .primary)
                    .lineLimit(1)

                HStack {
                    Text(file.metadata?.displayArtist ?? "Unknown Artist")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let duration = file.metadata?.duration {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Playing indicator
            if isCurrentTrack && playerViewModel.playerState.playbackState == .playing {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                    .symbolEffect(.variableColor.iterative)
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
    List {
        MusicFileRowView(file: MusicFile(url: URL(fileURLWithPath: "/test.mp3")))
    }
    .environmentObject(PlayerViewModel())
}
