import SwiftUI

@main
struct PocketMusicApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var libraryViewModel = MusicLibraryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerViewModel)
                .environmentObject(libraryViewModel)
        }
    }
}
