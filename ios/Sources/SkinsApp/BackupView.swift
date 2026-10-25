import SkinsCore
import SwiftUI
import UniformTypeIdentifiers

struct JournalDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }
  var data: Data
  init(state: AppState) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    data = try encoder.encode(state)
  }
  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
struct BackupView: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @ViewState private var document: JournalDocument?
  @ViewState private var exporting = false
  @ViewState private var importing = false
  @ViewState private var pending: AppState?
  @ViewState private var confirmImport = false
  @ViewState private var error: String?
  @ViewState private var done: String?
  var body: some View {
    NavigationStack {
      Form {
        Section("このiPhoneの記録") {
          LabeledContent("登録アイテム", value: "\(store.state.products.count)点")
          LabeledContent("肌の記録", value: "\(store.state.records.count)日")
        }
        Section {
          Button("バックアップを書き出す") {
            SkinsStyle.feedback()
            do {
              document = try JournalDocument(state: store.state)
              exporting = true
            } catch { self.error = error.localizedDescription }
          }
          Button("バックアップを読み込む") {
            SkinsStyle.feedback()
            importing = true
          }
        } footer: {
          Text("JSONファイルで保存・復元できます。読み込み前のデータも端末内に保持します。")
        }
        Section("Web版からの移行") {
          Text("Web版で書き出したSkinsのJSONバックアップを読み込めます。ブラウザ内のデータは自動では転送されません。").font(.subheadline)
        }
        if let done { Section { Text(done).foregroundStyle(.secondary) } }
      }.navigationTitle("データとバックアップ").navigationBarTitleDisplayModeCompat().toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("閉じる") {
            SkinsStyle.feedback()
            dismiss()
          }
        }
      }
    }
    .fileExporter(
      isPresented: $exporting, document: document, contentType: .json,
      defaultFilename: "skins-\(DayKey.today)"
    ) { result in
      switch result {
      case .success: done = "バックアップを書き出しました。"
      case .failure(let failure): error = failure.localizedDescription
      }
    }
    .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
      do {
        let url = try result.get()
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard (values.fileSize ?? 0) <= 10_000_000 else {
          throw SkinsError.invalid("10MB以下のバックアップを選んでください。")
        }
        pending = try JSONDecoder().decode(AppState.self, from: Data(contentsOf: url)).validated()
        confirmImport = true
      } catch { self.error = error.localizedDescription }
    }
    .confirmationDialog(
      "\(pending?.records.count ?? 0)日分の記録と\(pending?.products.count ?? 0)点の商品で、この端末のデータを置き換えますか？",
      isPresented: $confirmImport, titleVisibility: .visible
    ) {
      Button("読み込む") {
        SkinsStyle.feedback()
        if let pending {
          do {
            try store.restore(pending)
            done = "バックアップを復元しました。"
          } catch { self.error = error.localizedDescription }
        }
        pending = nil
      }
      Button("キャンセル", role: .cancel) {
        SkinsStyle.feedback()
        pending = nil
      }
    }
    .alert(
      "データを確認してください", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    ) {
      Button("閉じる", role: .cancel) {
        SkinsStyle.feedback()
        error = nil
      }
    } message: {
      Text(error ?? "")
    }
  }
}
