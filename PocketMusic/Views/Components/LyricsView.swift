import SwiftUI

// MARK: - Lyrics View
/// A view that displays synchronized lyrics with smooth scrolling and highlighting
/// Mimics Apple Music's lyrics display style
struct LyricsView: View {
    /// The lyrics to display
    let lyrics: Lyrics

    /// Current playback time in seconds
    let currentTime: TimeInterval

    /// Whether to show in compact mode (smaller font, less spacing)
    var compactMode: Bool = false

    /// Namespace for matched geometry animations
    @Namespace private var animation

    var body: some View {
        Group {
            if lyrics.isSynced, let lines = lyrics.syncedLines {
                // Time-synced lyrics with scrolling
                syncedLyricsView(lines: lines)
            } else if let plainText = lyrics.plainText, !plainText.isEmpty {
                // Plain text lyrics (no timing)
                plainLyricsView(text: plainText)
            } else {
                // No lyrics available
                emptyLyricsView
            }
        }
    }

    // MARK: - Synced Lyrics View
    /// Display time-synced lyrics with auto-scrolling and highlighting
    private func syncedLyricsView(lines: [LyricLine]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: compactMode ? 8 : 16) {
                    // Add top spacer for better centering
                    Spacer()
                        .frame(height: compactMode ? 100 : 200)

                    ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                        let isActive = isLineActive(line, at: index, in: lines)
                        let isPast = isPastLine(line, at: index, in: lines)

                        lyricsLineView(
                            text: line.text,
                            isActive: isActive,
                            isPast: isPast,
                            isEmpty: line.text.isEmpty
                        )
                        .id(line.id)
                    }

                    // Add bottom spacer
                    Spacer()
                        .frame(height: compactMode ? 100 : 200)
                }
                .padding(.horizontal, compactMode ? 20 : 30)
            }
            .onChange(of: currentTime) { _, newTime in
                // Auto-scroll to current line
                if let currentLineIndex = lyrics.currentLineIndex(at: newTime),
                   currentLineIndex < lines.count {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lines[currentLineIndex].id, anchor: .center)
                    }
                }
            }
            .onAppear {
                // Scroll to current position on appear
                if let currentLineIndex = lyrics.currentLineIndex(at: currentTime),
                   currentLineIndex < lines.count {
                    proxy.scrollTo(lines[currentLineIndex].id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Plain Text Lyrics View
    /// Display plain text lyrics without timing information
    private func plainLyricsView(text: String) -> some View {
        ScrollView {
            Text(text)
                .font(compactMode ? .body : .title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(compactMode ? 8 : 12)
                .padding(.horizontal, compactMode ? 20 : 30)
                .padding(.vertical, compactMode ? 40 : 60)
        }
    }

    // MARK: - Empty Lyrics View
    /// Show when no lyrics are available
    private var emptyLyricsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.system(size: compactMode ? 40 : 60))
                .foregroundColor(.white.opacity(0.3))

            Text("暂无歌词")
                .font(compactMode ? .body : .title3)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Lyrics Line View
    /// Individual lyric line with styling based on state
    private func lyricsLineView(text: String, isActive: Bool, isPast: Bool, isEmpty: Bool) -> some View {
        Text(isEmpty ? "♪" : text)
            .font(isActive ? (compactMode ? .title3 : .largeTitle) : (compactMode ? .body : .title2))
            .fontWeight(isActive ? .bold : .regular)
            .foregroundColor(
                isActive ? .white :
                isPast ? .white.opacity(0.5) :
                .white.opacity(0.4)
            )
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .scaleEffect(isActive ? 1.0 : 0.85)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            .shadow(
                color: isActive ? .white.opacity(0.3) : .clear,
                radius: isActive ? 8 : 0
            )
            .padding(.vertical, compactMode ? 4 : 8)
    }

    // MARK: - Helper Methods
    /// Check if a lyric line is currently active
    private func isLineActive(_ line: LyricLine, at index: Int, in lines: [LyricLine]) -> Bool {
        guard index < lines.count else { return false }

        let nextTimestamp: TimeInterval? = index + 1 < lines.count ? lines[index + 1].timestamp : nil
        return line.isActive(at: currentTime, nextLineTimestamp: nextTimestamp)
    }

    /// Check if a lyric line has already passed
    private func isPastLine(_ line: LyricLine, at index: Int, in lines: [LyricLine]) -> Bool {
        guard index < lines.count else { return false }

        // Check if there's a next line and current time is past it
        if index + 1 < lines.count {
            return currentTime >= lines[index + 1].timestamp
        }

        // For the last line, it's past if we're well beyond its timestamp
        return currentTime > line.timestamp + 3.0
    }
}

// MARK: - Preview
#Preview {
    let sampleLyrics = Lyrics(
        syncedLines: [
            LyricLine(timestamp: 0, text: "第一句歌词"),
            LyricLine(timestamp: 3, text: "第二句歌词"),
            LyricLine(timestamp: 6, text: "第三句歌词"),
            LyricLine(timestamp: 9, text: "第四句歌词"),
            LyricLine(timestamp: 12, text: "")
        ]
    )

    return ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        LyricsView(lyrics: sampleLyrics, currentTime: 3.5)
    }
}
