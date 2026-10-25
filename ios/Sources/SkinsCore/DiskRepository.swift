import Foundation

public struct DiskRepository: Sendable {
  public let url: URL
  public init(url: URL) { self.url = url }
  public func load() throws -> AppState? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    return try JSONDecoder().decode(AppState.self, from: Data(contentsOf: url)).validated()
  }
  public func save(_ state: AppState) throws {
    _ = try state.validated()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(state)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    #if os(iOS)
      try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    #else
      try data.write(to: url, options: .atomic)
    #endif
  }
}
