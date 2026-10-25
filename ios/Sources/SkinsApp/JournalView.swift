import SkinsCore
import SwiftUI

struct JournalView: View {
  @Environment(AppStore.self) private var store
  @Environment(\.scenePhase) private var scenePhase
  @ViewState private var today = DayKey.today
  @ViewState private var selected = DayKey.today
  @ViewState private var editing = false
  @ViewState private var backup = false
  var current: SkinRecord? { store.record(selected) }
  var days: [String] { DayKey.recentDays(ending: DayKey.date(today) ?? Date()) }
  var recentRecords: [SkinRecord] { store.state.records.filter { days.contains($0.date) } }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        AppHeader()
        HStack {
          Text("記録").font(.largeTitle.weight(.medium))
          Spacer()
          Button("今日") {
            SkinsStyle.feedback()
            today = DayKey.today
            selected = today
          }
          Button {
            SkinsStyle.feedback()
            backup = true
          } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
          }.accessibilityLabel("バックアップとデータ移行")
        }
        VStack(alignment: .leading, spacing: 8) {
          Text("直近3週間").font(.title2.weight(.medium))
          if let first = days.first, let start = DayKey.date(first), let end = DayKey.date(today) {
            Text(
              "\(start.formatted(.dateTime.month().day())) 〜 \(end.formatted(.dateTime.month().day()))"
            )
            .font(.subheadline).foregroundStyle(SkinsStyle.muted)
          }
          Text(
            "\(recentRecords.count)日記録 · ケア完了 \(recentRecords.filter { $0.care == .done }.count)日"
          )
          .font(.caption).foregroundStyle(SkinsStyle.muted)
        }
        VStack(spacing: 8) {
          HStack {
            ForEach(Array(days.prefix(7)), id: \.self) { key in
              let weekday = DayKey.calendar.component(.weekday, from: DayKey.date(key)!)
              Text(["日", "月", "火", "水", "木", "金", "土"][weekday - 1]).font(.caption).foregroundStyle(
                SkinsStyle.muted
              ).frame(maxWidth: .infinity)
            }
          }
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 6
          ) {
            ForEach(days, id: \.self) { key in dayCell(key) }
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
        SkinsStyle.feedback()
        editing = true
      } label: {
        Label("記録する", systemImage: "plus").font(.headline).padding(.horizontal, 20).padding(
          .vertical, 16
        ).background(SkinsStyle.accent, in: Capsule()).foregroundStyle(.white).shadow(
          color: SkinsStyle.accent.opacity(0.2), radius: 8, y: 4)
      }.buttonStyle(SkinsPressStyle()).padding(20)
    }.navigationTitle("")
      .sheet(isPresented: $editing) {
        RecordEditor(
          date: selected,
          onSave: { key in
            selected = key
            today = DayKey.today
          })
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { today = DayKey.today }
      }
      .sheet(isPresented: $backup) { BackupView() }
  }
  func dayCell(_ key: String) -> some View {
    let record = store.record(key)
    let future = key > DayKey.today
    return Button {
      SkinsStyle.feedback()
      selected = key
      SkinsStyle.feedback()
    } label: {
      VStack(spacing: 5) {
        Text(
          key.suffix(2) == "01"
            ? "\(Int(key.dropFirst(5).prefix(2)) ?? 1)/1" : String(Int(key.suffix(2)) ?? 1)
        ).font(.subheadline.monospacedDigit()).underline(
          key == DayKey.today)
        Text(record?.mood.shortLabel ?? "・").font(.system(size: 10))
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
    }.buttonStyle(SkinsPressStyle()).disabled(future).accessibilityLabel(
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
        Button("この日の記録を編集 →") {
          SkinsStyle.feedback()
          editing = true
        }.font(.subheadline)
      } else {
        Text("この日の肌とケアを記録しましょう。").foregroundStyle(SkinsStyle.muted).font(.subheadline).padding(
          .vertical, 20)
      }
    }
  }
}
