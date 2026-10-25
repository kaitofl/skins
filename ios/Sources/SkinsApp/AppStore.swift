import Foundation
import Observation
import SkinsCore

struct ProductKnowledge: Decodable {
  var features: String
  var ingredients: [[String]]
  var recommend: [String]
  var source: String
}
@MainActor @Observable final class AppStore {
  private(set) var state: AppState
  private(set) var loadError: String?
  var message: String?
  let repository: DiskRepository
  let knowledge: [String: ProductKnowledge]
  init(directory: URL? = nil) {
    let folder =
      directory
      ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Skins", isDirectory: true)
    repository = DiskRepository(url: folder.appendingPathComponent("journal.json"))
    let products =
      (try? JSONDecoder().decode([Product].self, from: Self.resource("products"))) ?? []
    knowledge =
      (try? JSONDecoder().decode([String: ProductKnowledge].self, from: Self.resource("knowledge")))
      ?? [:]
    state = AppState(products: products)
    do { if let loaded = try repository.load() { state = loaded } } catch {
      loadError =
        "保存データを読み込めませんでした。元のファイルは保持しています。バックアップを読み込んで復元してください。\n\(error.localizedDescription)"
    }
  }
  static func resource(_ name: String) throws -> Data {
    #if SWIFT_PACKAGE
      let bundle = Bundle.module
    #else
      let bundle = Bundle.main
    #endif
    guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Content")
    else { throw SkinsError.invalid("商品データが見つかりません。") }
    return try Data(contentsOf: url)
  }
  @discardableResult func commit(_ transform: (inout AppState) throws -> Void) -> Bool {
    guard loadError == nil else {
      message = loadError
      return false
    }
    var next = state
    do {
      try transform(&next)
      try repository.save(next)
      state = next
      return true
    } catch {
      message = error.localizedDescription
      return false
    }
  }
  func restore(_ imported: AppState) throws {
    let valid = try imported.validated()
    // Retain the existing file before replacing it with an imported backup.
    if FileManager.default.fileExists(atPath: repository.url.path) {
      let backup = repository.url.deletingLastPathComponent().appendingPathComponent(
        "before-import-\(UUID().uuidString).json")
      try FileManager.default.copyItem(at: repository.url, to: backup)
    }
    try repository.save(valid)
    state = valid
    loadError = nil
  }
  func record(_ key: String) -> SkinRecord? { state.records.first { $0.date == key } }
  func journal(_ product: Product) -> ProductJournal {
    state.productJournals[product.journalKey] ?? ProductJournal()
  }
  func info(_ product: Product) -> ProductKnowledge? {
    knowledge[String([5102: 5001, 5103: 5002, 5106: 5004][product.id] ?? product.id)]
  }
  func moveProduct(_ id: Int, to targetID: Int) -> Bool {
    var next = state
    guard next.moveProduct(id, to: targetID) else { return false }
    return commit { $0 = next }
  }
  func saveProduct(_ product: Product) -> Bool {
    commit { next in
      if let index = next.products.firstIndex(where: { $0.id == product.id }) {
        next.products[index] = product
      } else {
        next.products.append(product)
      }
    }
  }
}
