import Foundation

public enum CareTime: String, Codable, CaseIterable, Sendable {
  case am, pm
  public var title: String { self == .am ? "朝のケア" : "夜のケア" }
  public var symbol: String { self == .am ? "sun.max" : "moon" }
}
public enum SkinMood: String, Codable, CaseIterable, Sendable {
  case good = "良い"
  case normal = "ふつう"
  case uneasy = "ゆらぎ気味"
  case dry = "乾燥が気になる"
  public var shortLabel: String {
    switch self {
    case .good: "良い"
    case .normal: "ふつう"
    case .uneasy: "ゆらぎ"
    case .dry: "乾燥"
    }
  }
}
public enum CareStatus: String, Codable, CaseIterable, Sendable {
  case done = "できた"
  case partial = "一部できた"
  case rest = "お休み"
  case unrecorded = "未記録"
  public var symbol: String {
    switch self {
    case .done: "checkmark"
    case .partial: "circle.lefthalf.filled"
    case .rest: "minus"
    case .unrecorded: ""
    }
  }
}
public enum SpotStatus: String, Codable, CaseIterable, Sendable {
  case new, worse, better
  public var title: String {
    switch self {
    case .new: "新しくできた"
    case .worse: "悪化した"
    case .better: "良くなってきた"
    }
  }
}
public struct AcneSpot: Identifiable, Codable, Equatable, Sendable {
  public var id: String
  public var x: Double
  public var y: Double
  public var area: String
  public var status: SpotStatus?
  public init(
    id: String = UUID().uuidString, x: Double, y: Double, area: String? = nil,
    status: SpotStatus? = .new
  ) {
    self.id = id
    self.x = x
    self.y = y
    self.area = area ?? Self.area(x: x, y: y)
    self.status = status
  }
  public static func area(x: Double, y: Double) -> String {
    if y < 34 { return "おでこ" }
    if y > 79 { return "あご" }
    if y > 69 && (x < 30 || x > 70) { return "フェイスライン" }
    if x > 40 && x < 60 { return "鼻" }
    return x < 50 ? "右頬" : "左頬"
  }
  public static func isOnFace(x: Double, y: Double) -> Bool {
    y >= 8 && y <= 88 && pow((x - 50) / 34, 2) + pow((y - 46) / 42, 2) <= 1
  }
}
public struct Product: Identifiable, Codable, Equatable, Sendable {
  public var id: Int
  public var name: String
  public var shortName: String?
  public var brand: String
  public var type: String
  public var time: CareTime
  public var days: [Int]
  public var asNeeded: Bool?
  public var asset: String?
  public var sourceUrl: String?
  public var note: String?
  public init(
    id: Int, name: String, brand: String = "", type: String = "美容液", time: CareTime = .am,
    days: [Int] = Array(0...6)
  ) {
    self.id = id
    self.name = name
    self.brand = brand
    self.type = type
    self.time = time
    self.days = days
  }
  public var journalKey: String { sourceUrl ?? "\(brand):\(name)" }
  public var displayName: String { shortName ?? name }
  public var daysLabel: String {
    if asNeeded == true { return "必要な日" }
    let d = Array(Set(days)).sorted()
    if d.count == 7 { return "毎日" }
    if d.isEmpty { return "未設定" }
    return d.map { DayKey.weekdays[$0] }.joined(separator: "・")
  }
}
public struct ProductJournal: Codable, Equatable, Sendable {
  public var purchasedAt: String
  public var startedAt: String
  public init(purchasedAt: String = "", startedAt: String = "") {
    self.purchasedAt = purchasedAt
    self.startedAt = startedAt
  }
}
public struct SkinRecord: Identifiable, Codable, Equatable, Sendable {
  public var id: String { date }
  public var date: String
  public var mood: SkinMood
  public var sleep: String
  public var care: CareStatus?
  public var acne: String
  public var acneSpots: [AcneSpot]?
  public var treatment: String
  public var memo: String
  public init(
    date: String, mood: SkinMood = .normal, sleep: String = "7", care: CareStatus? = nil,
    acne: String = "なし", acneSpots: [AcneSpot]? = nil, treatment: String = "", memo: String = ""
  ) {
    self.date = date
    self.mood = mood
    self.sleep = sleep
    self.care = care
    self.acne = acne
    self.acneSpots = acneSpots
    self.treatment = treatment
    self.memo = memo
  }
  public mutating func updateAcneSummary() {
    guard let spots = acneSpots else { return }
    acne =
      spots.isEmpty
      ? "なし" : spots.map { "\($0.area)（\($0.status?.title ?? "未選択")）" }.joined(separator: "、")
  }
  public var validationMessage: String? {
    guard DayKey.date(date) != nil, date <= DayKey.today else { return "今日までの日付を選んでください。" }
    guard let hours = Double(sleep), hours.isFinite, (0...24).contains(hours),
      (hours * 2).rounded() == hours * 2
    else { return "睡眠時間は0〜24時間、0.5時間単位で入力してください。" }
    if acneSpots?.contains(where: { $0.status == nil || !AcneSpot.isOnFace(x: $0.x, y: $0.y) })
      == true
    {
      return "それぞれの印の位置と状態を確認してください。"
    }
    return nil
  }
}
public struct AppState: Codable, Equatable, Sendable {
  public var schemaVersion: Int
  public var products: [Product]
  public var records: [SkinRecord]
  public var skin: String
  public var productJournals: [String: ProductJournal]
  public init(
    products: [Product] = [], records: [SkinRecord] = [], skin: String = "混合肌",
    productJournals: [String: ProductJournal] = [:]
  ) {
    schemaVersion = 1
    self.products = products
    self.records = records
    self.skin = skin
    self.productJournals = productJournals
  }
  enum CodingKeys: String, CodingKey {
    case schemaVersion, products, records, skin, productJournals
  }
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    products = try c.decode([Product].self, forKey: .products)
    records = try c.decodeIfPresent([SkinRecord].self, forKey: .records) ?? []
    skin = try c.decodeIfPresent(String.self, forKey: .skin) ?? "混合肌"
    productJournals =
      try c.decodeIfPresent([String: ProductJournal].self, forKey: .productJournals) ?? [:]
  }
  public mutating func upsert(_ record: SkinRecord) throws {
    if let message = record.validationMessage { throw SkinsError.invalid(message) }
    records.removeAll { $0.date == record.date }
    records.append(record)
    records.sort { $0.date > $1.date }
  }
  /// Move inside a routine, preserving the exact positions and order of the other routine.
  /// The destination is the target's original index, matching a native collection move.
  @discardableResult public mutating func moveProduct(_ id: Int, to targetID: Int) -> Bool {
    guard id != targetID,
      let source = products.first(where: { $0.id == id }),
      let target = products.first(where: { $0.id == targetID }), source.time == target.time
    else { return false }
    let positions = products.indices.filter { products[$0].time == source.time }
    var routine = positions.map { products[$0] }
    guard let from = routine.firstIndex(where: { $0.id == id }),
      let to = routine.firstIndex(where: { $0.id == targetID })
    else { return false }
    let moving = routine.remove(at: from)
    routine.insert(moving, at: to)
    for (index, position) in positions.enumerated() { products[position] = routine[index] }
    return true
  }

  public func previousSpots(before date: String) -> [AcneSpot] {
    let previous = records.filter { $0.date < date && !($0.acneSpots ?? []).isEmpty }.sorted {
      $0.date > $1.date
    }.first
    return (previous?.acneSpots ?? []).map {
      var spot = $0
      spot.status = nil
      return spot
    }
  }
  public func validated() throws -> Self {
    guard schemaVersion == 1 else { throw SkinsError.invalid("このバックアップのバージョンには対応していません。") }
    guard Set(products.map(\.id)).count == products.count,
      Set(records.map(\.date)).count == records.count
    else { throw SkinsError.invalid("重複する商品または日付があります。") }
    for p in products {
      guard !p.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !p.days.isEmpty || p.asNeeded == true, p.days.allSatisfy({ (0...6).contains($0) })
      else { throw SkinsError.invalid("商品の名前と使用曜日を確認してください。") }
      if let url = p.sourceUrl, URL(string: url)?.scheme != "https" {
        throw SkinsError.invalid("商品リンクはhttpsに対応したURLを指定してください。")
      }
    }
    for r in records { if let message = r.validationMessage { throw SkinsError.invalid(message) } }
    return self
  }
}
public enum SkinsError: LocalizedError {
  case invalid(String)
  public var errorDescription: String? {
    switch self {
    case .invalid(let message): message
    }
  }
}
public enum DayKey {
  public static let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
  public static var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.locale = Locale(identifier: "ja_JP")
    return c
  }
  public static var today: String { string(Date()) }
  public static func string(_ date: Date) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
  }
  public static func date(_ key: String) -> Date? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    guard
      let result = calendar.date(
        from: DateComponents(year: parts[0], month: parts[1], day: parts[2])), string(result) == key
    else { return nil }
    return result
  }
  public static func monthDays(_ date: Date) -> [String?] {
    let first = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    let offset = calendar.component(.weekday, from: first) - 1
    return Array(repeating: nil, count: offset)
      + (calendar.range(of: .day, in: .month, for: first) ?? 1..<1).map {
        string(calendar.date(byAdding: .day, value: $0 - 1, to: first)!)
      }
  }
}
