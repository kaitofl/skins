import SkinsCore
import SwiftUI

struct JournalView: View {
  @Environment(AppStore.self) private var store
  @ViewState private var month = Date()
  @ViewState private var selected = DayKey.today
  @ViewState private var editing = false
  @ViewState private var backup = false
  var current: SkinRecord? { store.record(selected) }
  var monthKey: String { String(DayKey.string(month).prefix(7)) }
  var monthly: [SkinRecord] { store.state.records.filter { $0.date.hasPrefix(monthKey) } }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AppHeader()
        HStack {
          Text("記録").font(.largeTitle.weight(.medium))
          Spacer()
          Button("今日") {
            month = Date()
            selected = DayKey.today
          }
          Button {
            backup = true
          } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
          }.accessibilityLabel("バックアップとデータ移行")
        }
        monthHeader
        VStack(spacing: 8) {
          HStack {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) {
              Text($0).font(.caption).foregroundStyle(SkinsStyle.muted).frame(maxWidth: .infinity)
            }
          }
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6
          ) {
            ForEach(Array(DayKey.monthDays(month).enumerated()), id: \.offset) { _, key in
              if let key { dayCell(key) } else { Color.clear.frame(height: 70) }
            }
          }
        }
        HStack(spacing: 12) {
          ForEach(SkinMood.allCases, id: \.self) { mood in
            HStack(spacing: 4) {
              Circle().fill(mood.color.opacity(0.6)).frame(width: 6, height: 6)
              Text(mood.shortLabel).font(.caption2)
            }
          }
        }.frame(maxWidth: .infinity).foregroundStyle(SkinsStyle.muted)
        Text("ケア：✓ できた　◐ 一部できた　− お休み").font(.caption2).foregroundStyle(SkinsStyle.muted).frame(
          maxWidth: .infinity)
        Divider()
        dayDetail
      }.padding(22).padding(.bottom, 88).foregroundStyle(SkinsStyle.ink)
    }.overlay(alignment: .bottomTrailing) {
      Button {
        editing = true
      } label: {
        Label("記録する", systemImage: "plus").font(.headline).padding(.horizontal, 20).padding(
          .vertical, 16
        ).background(SkinsStyle.accent, in: Capsule()).foregroundStyle(.white).shadow(
          color: SkinsStyle.accent.opacity(0.2), radius: 8, y: 4)
      }.buttonStyle(.plain).padding(20)
    }.navigationTitle("")
      .sheet(isPresented: $editing) {
        RecordEditor(
          date: selected,
          onSave: { key in
            selected = key
            month = DayKey.date(key) ?? Date()
          })
      }
      .sheet(isPresented: $backup) { BackupView() }
  }
  var monthHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 8) {
        Text(month, format: .dateTime.year().month(.wide)).font(.title2.weight(.medium))
        Text("\(monthly.count)日記録 · ケア完了 \(monthly.filter{$0.care == .done}.count)日").font(.caption)
          .foregroundStyle(SkinsStyle.muted)
      }
      Spacer()
      Button {
        shift(-1)
      } label: {
        Image(systemName: "chevron.left").frame(width: 40, height: 44)
      }.accessibilityLabel("前の月")
      Button {
        shift(1)
      } label: {
        Image(systemName: "chevron.right").frame(width: 40, height: 44)
      }.accessibilityLabel("次の月").disabled(monthKey >= String(DayKey.today.prefix(7)))
    }
  }
  func shift(_ delta: Int) {
    guard
      let first = DayKey.calendar.date(
        from: DayKey.calendar.dateComponents([.year, .month], from: month)),
      let next = DayKey.calendar.date(byAdding: .month, value: delta, to: first)
    else { return }
    month = next
    selected =
      String(DayKey.string(next).prefix(7)) == String(DayKey.today.prefix(7))
      ? DayKey.today : DayKey.string(next)
    SkinsStyle.feedback()
  }
  func dayCell(_ key: String) -> some View {
    let record = store.record(key)
    let future = key > DayKey.today
    return Button {
      selected = key
      SkinsStyle.feedback()
    } label: {
      VStack(spacing: 5) {
        Text(String(Int(key.suffix(2)) ?? 1)).font(.subheadline.monospacedDigit()).underline(
          key == DayKey.today)
        Text(record?.mood.shortLabel ?? " ").font(.system(size: 9))
        if let care = record?.care, !care.symbol.isEmpty {
          Image(systemName: care.symbol).font(.system(size: 10)).frame(height: 10)
        } else {
          Color.clear.frame(height: 10)
        }
      }.frame(maxWidth: .infinity, minHeight: 70).foregroundStyle(
        future ? Color.gray.opacity(0.3) : record?.mood.color ?? SkinsStyle.muted
      )
      .background(
        (record?.mood.color ?? SkinsStyle.surface).opacity(record == nil ? 1 : 0.13),
        in: RoundedRectangle(cornerRadius: 11)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 11).stroke(
          selected == key ? SkinsStyle.accent : .clear, lineWidth: 1.5))
    }.buttonStyle(.plain).disabled(future).accessibilityLabel(
      "\(key)、\(record?.mood.rawValue ?? "未記録")、ケア\(record?.care?.rawValue ?? "未記録")"
    ).accessibilityAddTraits(selected == key ? .isSelected : [])
  }
  var dayDetail: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        Text(DayKey.date(selected) ?? Date(), format: .dateTime.month().day()).font(.headline)
        Text("の記録").font(.headline)
        Spacer()
        if let current {
          Text(current.mood.rawValue).font(.caption).foregroundStyle(current.mood.color)
        }
      }
      if let current {
        HStack {
          VStack(alignment: .leading, spacing: 7) {
            Text("スキンケア").font(.caption)
            Text(current.care?.rawValue ?? "未記録").font(.title3)
          }.frame(maxWidth: .infinity, alignment: .leading)
          Divider()
          VStack(alignment: .leading, spacing: 7) {
            Text("睡眠").font(.caption)
            Text(current.sleep + " 時間").font(.title3)
          }.frame(maxWidth: .infinity, alignment: .leading)
        }
        if let spots = current.acneSpots, !spots.isEmpty {
          ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
            HStack {
              Text("\(index+1) · \(spot.area)")
              Spacer()
              Text(spot.status?.title ?? "未記録").foregroundStyle(
                spot.status?.color ?? SkinsStyle.muted)
            }.font(.subheadline)
          }
        } else {
          Text("ニキビ：" + current.acne).font(.subheadline)
        }
        if !current.memo.isEmpty { Text(current.memo).font(.body).lineSpacing(5) }
        if !current.treatment.isEmpty { Text("美容施術：" + current.treatment).font(.subheadline) }
        Button("この日の記録を編集 →") { editing = true }.font(.subheadline)
      } else {
        Text("この日の肌とケアを記録しましょう。").foregroundStyle(SkinsStyle.muted).font(.subheadline).padding(
          .vertical, 20)
      }
    }
  }
}
