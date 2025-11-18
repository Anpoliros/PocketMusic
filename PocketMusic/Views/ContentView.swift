import SwiftUI

struct ContentView: View {
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel
    @State private var showingImportSheet = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            NavigationView {
                FileExplorerView()
            }
            .tabItem {
                Label("音乐库", systemImage: "music.note.list")
            }
            .tag(0)

            // Playlists Tab
            PlaylistsView()
                .tabItem {
                    Label("播放列表", systemImage: "music.note")
                }
                .tag(1)

            // Now Playing Tab
            NavigationView {
                PlayerView()
            }
            .tabItem {
                Label("正在播放", systemImage: "play.circle.fill")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicLibraryViewModel())
        .environmentObject(PlayerViewModel())
}
