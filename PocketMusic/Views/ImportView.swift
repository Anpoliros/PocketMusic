import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var libraryViewModel: MusicLibraryViewModel

    @State private var showingFilePicker = false
    @State private var preserveStructure = true
    @State private var importSource: ImportSource = .files

    enum ImportSource {
        case files
        case iCloud
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("导入来源", selection: $importSource) {
                        Label("本地文件", systemImage: "doc.on.doc")
                            .tag(ImportSource.files)
                        Label("iCloud Drive", systemImage: "icloud")
                            .tag(ImportSource.iCloud)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("保留文件夹结构", isOn: $preserveStructure)
                } header: {
                    Text("导入选项")
                } footer: {
                    Text("开启后将保留原始的文件夹层级结构，关闭后所有文件将导入到同一目录下")
                }

                Section {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("选择文件", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("支持的格式", systemImage: "info.circle")
                            .font(.headline)

                        Text("• MP3, M4A, AAC")
                        Text("• WAV, FLAC")
                        Text("• AIFF, ALAC")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("导入音乐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: true
            ) { result in
                handleImport(result: result)
            }
        }
    }

    private var allowedTypes: [UTType] {
        [
            .audio,
            .mp3,
            .mpeg4Audio,
            .wav,
            .aiff,
            .folder
        ]
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            libraryViewModel.importFiles(from: urls, preserveStructure: preserveStructure)
            dismiss()
        case .failure(let error):
            print("导入失败: \(error)")
        }
    }
}

#Preview {
    ImportView()
        .environmentObject(MusicLibraryViewModel())
}
