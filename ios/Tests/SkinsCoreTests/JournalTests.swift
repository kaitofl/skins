import Foundation
import SkinsCore

func upsertReplacesOnlySameDay() throws {
  var state = AppState(records: [SkinRecord(date: "2026-01-01", memo: "keep")])
  try state.upsert(SkinRecord(date: "2026-01-02", mood: .good, care: .done))
  try state.upsert(SkinRecord(date: "2026-01-02", mood: .dry, care: .partial))
  try check(state.records.count == 2)
  try check(state.records.first?.mood == .dry)
  try check(state.records.last?.memo == "keep")
}
func datesRejectOverflowAndFuture() throws {
  try check(DayKey.date("2024-02-29") != nil)
  try check(DayKey.date("2025-02-29") == nil)
  try check(DayKey.date("2026-13-01") == nil)
  try check(SkinRecord(date: "2999-01-01").validationMessage != nil)
  try check(SkinRecord(date: "2026-01-01", sleep: "7.25").validationMessage != nil)
  try check(SkinRecord(date: "2026-01-01", sleep: "nan").validationMessage != nil)
}
func calendarSundayAlignmentAndLeapYear() throws {
  let october = DayKey.monthDays(DayKey.date("2026-10-25")!)
  try check(october.prefix(4).allSatisfy { $0 == nil })
  try check(october[4] == "2026-10-01")
  let leap = DayKey.monthDays(DayKey.date("2024-02-01")!).compactMap { $0 }
  try check(leap.count == 29)
  try check(leap.last == "2024-02-29")
}
func carryKeepsIdentityButRequiresTodaysStatus() throws {
  let spot = AcneSpot(id: "tracked", x: 30, y: 55, status: .worse)
  let state = AppState(records: [SkinRecord(date: "2026-01-01", acneSpots: [spot])])
  var carried = state.previousSpots(before: "2026-01-02")
  try check(carried.first?.id == "tracked")
  try check(carried.first?.status == nil)
  try check(SkinRecord(date: "2026-01-02", acneSpots: carried).validationMessage != nil)
  carried[0].status = .better
  try check(state.records[0].acneSpots?[0].status == .worse)
  try check(SkinRecord(date: "2026-01-02", acneSpots: carried).validationMessage == nil)
}
func diskRoundTripAndInvalidWritePreservesFile() throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: directory) }
  let repository = DiskRepository(url: directory.appendingPathComponent("journal.json"))
  let valid = AppState(records: [
    SkinRecord(
      date: "2026-01-01", care: .done, acneSpots: [AcneSpot(x: 30, y: 55, status: .better)])
  ])
  try repository.save(valid)
  try check(try repository.load() == valid)
  let original = try Data(contentsOf: repository.url)
  let invalid = AppState(records: [SkinRecord(date: "not-a-date")])
  try expectThrows { try repository.save(invalid) }
  try check(try Data(contentsOf: repository.url) == original)
}
func webBackupDecodesAndRetainsLegacyAcne() throws {
  let data = Data(
    #"{"products":[],"records":[{"date":"2026-01-01","mood":"良い","sleep":"7.5","acne":"あご","treatment":"","memo":"legacy"}],"skin":"混合肌","saved":[]}"#
      .utf8)
  let state = try JSONDecoder().decode(AppState.self, from: data).validated()
  try check(state.records[0].acne == "あご")
  try check(state.records[0].acneSpots == nil)
  try check(state.records[0].care == nil)
}
func validatesSpotBoundsAndProductSchedule() throws {
  try check(AcneSpot.isOnFace(x: 30, y: 55))
  try check(!AcneSpot.isOnFace(x: 0, y: 0))
  try check(!AcneSpot.isOnFace(x: 50, y: 97))
  try check(Product(id: 1, name: "Test", days: [2, 5]).daysLabel == "水・土")
  let invalid = AppState(products: [Product(id: 1, name: "Test", days: [7])])
  try expectThrows { _ = try invalid.validated() }
}

private func check(
  _ condition: @autoclosure () throws -> Bool, file: StaticString = #filePath, line: UInt = #line
) throws {
  if try !condition() { throw SkinsError.invalid("Check failed at \(file):\(line)") }
}
private func expectThrows(_ action: () throws -> Void) throws {
  do { try action() } catch { return }
  throw SkinsError.invalid("Expected an invalid operation to fail")
}
@main struct CoreChecks {
  static func main() throws {
    let checks: [(String, () throws -> Void)] = [
      ("Daily records update without duplicates", upsertReplacesOnlySameDay),
      ("Dates and sleep validation", datesRejectOverflowAndFuture),
      ("Calendar alignment and leap years", calendarSundayAlignmentAndLeapYear),
      (
        "Tracked spots retain identity and independent daily status",
        carryKeepsIdentityButRequiresTodaysStatus
      ),
      (
        "Atomic persistence and invalid-write protection", diskRoundTripAndInvalidWritePreservesFile
      ),
      ("Web backup and legacy records", webBackupDecodesAndRetainsLegacyAcne),
      ("Face bounds and usage schedules", validatesSpotBoundsAndProductSchedule),
    ]
    for (name, run) in checks {
      try run()
      print("PASS: " + name)
    }
    print("\(checks.count) checks passed")
    if CommandLine.arguments.count > 1 {
      let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
      let imported = try JSONDecoder().decode(AppState.self, from: data).validated()
      print("PASS: exported Web backup — \(imported.products.count) products, \(imported.records.count) records")
    }
  }
}
