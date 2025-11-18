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

            // Now Playing Tab
            NavigationView {
                PlayerView()
            }
            .tabItem {
                Label("正在播放", systemImage: "play.circle.fill")
            }
            .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicLibraryViewModel())
        .environmentObject(PlayerViewModel())
}
