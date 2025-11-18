import SwiftUI

struct FileExplorerView: View {
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel
    @EnvironmentObject var playerViewModel: PlayerViewModel

    @State private var searchText = ""
    @State private var showingImportSheet = false
    @State private var navigationPath: [Folder] = []

    var body: some View {
        VStack(spacing: 0) {
            // Content
            if libraryViewModel.isLoading {
                ProgressView("加载中...")
            } else if let errorMessage = libraryViewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if searchText.isEmpty {
                // Folder browser
                folderContent
            } else {
                // Search results
                searchResults
            }
        }
        .navigationTitle(currentNavigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜索音乐")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("导入文件", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        libraryViewModel.loadLibrary()
                    } label: {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView()
        }
    }

    private var currentNavigationTitle: String {
        if !searchText.isEmpty {
            return "搜索结果"
        }
        return navigationPath.last?.name ?? "音乐库"
    }

    private var folderContent: some View {
        List {
            let currentFolder = navigationPath.last
            let folders = currentFolder?.subfolders ?? libraryViewModel.library.folders
            let files = currentFolder?.musicFiles ?? []

            // Folders
            if !folders.isEmpty {
                Section("文件夹") {
                    ForEach(folders) { folder in
                        Button {
                            navigationPath.append(folder)
                        } label: {
                            FolderRowView(folder: folder)
                        }
                    }
                }
            }

            // Files
            if !files.isEmpty {
                Section("音乐文件") {
                    ForEach(files) { file in
                        MusicFileRowView(file: file)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playerViewModel.play(track: file, from: files)
                            }
                    }
                }
            }

            // Empty state
            if folders.isEmpty && files.isEmpty {
                ContentUnavailableView(
                    "没有音乐文件",
                    systemImage: "music.note",
                    description: Text("点击右上角菜单导入音乐")
                )
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            if !navigationPath.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigationPath.removeLast()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                    }
                }
            }
        }
    }

    private var searchResults: some View {
        List {
            let results = libraryViewModel.searchFiles(query: searchText)

            if results.isEmpty {
                ContentUnavailableView.search
            } else {
                ForEach(results) { file in
                    MusicFileRowView(file: file)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerViewModel.play(track: file, from: results)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Folder Row
struct FolderRowView: View {
    let folder: Folder

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.blue)
                .font(.title3)

            VStack(alignment: .leading) {
                Text(folder.name)
                    .font(.body)
                    .foregroundColor(.primary)

                Text("\(folder.totalFileCount) 首歌曲")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        FileExplorerView()
    }
    .environmentObject(MusicLibraryViewModel())
    .environmentObject(PlayerViewModel())
}
