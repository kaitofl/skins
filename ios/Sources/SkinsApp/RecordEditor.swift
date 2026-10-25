import SkinsCore
import SwiftUI

struct RecordEditor: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let date: String
  var onSave: (String) -> Void = { _ in }
  @ViewState private var draft = SkinRecord(date: DayKey.today)
  @ViewState private var spots: [AcneSpot] = []
  @ViewState private var selectedSpot: String?
  @ViewState private var sleep = 7.0
  @ViewState private var care: CareStatus = .unrecorded
  @ViewState private var loaded = false
  @ViewState private var baseline = SkinRecord(date: DayKey.today)
  var dirty: Bool { snapshot != baseline }
  var snapshot: SkinRecord {
    var record = draft
    record.sleep = String(sleep)
    record.care = care
    if !spots.isEmpty || record.acne == "なし" || record.acneSpots != nil {
      record.acneSpots = spots
      record.updateAcneSummary()
    }
    return record
  }
  @ViewState private var pendingDate: Date?
  @ViewState private var confirmDate = false
  @ViewState private var confirmClose = false
  @ViewState private var error: String?
  @ViewState private var deleteRecord = false
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("今日の調子を、ひとつずつ。").font(.subheadline).foregroundStyle(SkinsStyle.muted)
          DatePicker(
            "日付",
            selection: Binding(
              get: { DayKey.date(draft.date) ?? Date() },
              set: { next in
                if dirty {
                  pendingDate = next
                  confirmDate = true
                } else {
                  load(DayKey.string(next))
                }
              }), in: ...Date(), displayedComponents: .date)
          Divider()
          SectionCaption(title: "肌の調子")
          ChoiceGrid(values: SkinMood.allCases, selection: $draft.mood, label: { $0.rawValue })
          Divider()
          SectionCaption(title: "昨夜の睡眠")
          Stepper(value: $sleep, in: 0...24, step: 0.5) {
            Text("\(sleep.formatted(.number.precision(.fractionLength(0...1)))) 時間").font(
              .title2.monospacedDigit())
          }.padding(16).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 14))
          Divider()
          SectionCaption(title: "スキンケアはできた？")
          ChoiceGrid(values: CareStatus.allCases, selection: $care, label: { $0.rawValue })
          Divider()
          HStack {
            SectionCaption(title: "ニキビの記録")
            Button("なしにする") {
              spots = []
              draft.acne = "なし"
              selectedSpot = nil
            }.font(.subheadline)
          }
          FaceMap(spots: $spots, selectedID: $selectedSpot)
          if spots.isEmpty, draft.acne != "なし", !draft.acne.isEmpty {
            Text("以前の記録：" + draft.acne).font(.subheadline).foregroundStyle(SkinsStyle.muted)
          }
          Button("前回の位置を引き継ぐ") { carrySpots() }.font(.subheadline).disabled(
            store.state.previousSpots(before: draft.date).isEmpty)
          Divider()
          SectionCaption(title: "肌のメモ（任意）")
          TextField("気になった変化、使ったアイテムなど", text: $draft.memo, axis: .vertical).lineLimit(3...6)
            .padding(14).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 12))
          SectionCaption(title: "美容施術（任意）")
          TextField("施術名・クリニック・経過など", text: $draft.treatment).padding(14).background(
            SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 12))
          if store.record(draft.date) != nil {
            Button("この日の記録を削除", role: .destructive) { deleteRecord = true }.font(.subheadline)
              .padding(.top, 8)
          }
        }.padding(24).foregroundStyle(SkinsStyle.ink)
      }.scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
          PrimaryButton(title: "記録を保存する", action: save).padding(18).background(.regularMaterial)
        }
        .navigationTitle(store.record(draft.date) == nil ? "肌を記録する" : "肌の記録を編集")
        .navigationBarTitleDisplayModeCompat()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") { if dirty { confirmClose = true } else { dismiss() } }
          }
        }
        .onAppear {
          if !loaded {
            load(date)
            loaded = true
          }
        }
        .confirmationDialog(
          "入力中の内容を破棄して日付を変更しますか？", isPresented: $confirmDate, titleVisibility: .visible
        ) {
          Button("日付を変更", role: .destructive) {
            if let pendingDate { load(DayKey.string(pendingDate)) }
            pendingDate = nil
          }
          Button("キャンセル", role: .cancel) { pendingDate = nil }
        }
        .confirmationDialog("入力中の内容を破棄しますか？", isPresented: $confirmClose, titleVisibility: .visible)
      { Button("破棄して閉じる", role: .destructive) { dismiss() } }
        .confirmationDialog("この日の記録を削除しますか？", isPresented: $deleteRecord, titleVisibility: .visible)
      {
        Button("削除", role: .destructive) {
          if store.commit({ $0.records.removeAll { $0.date == draft.date } }) { dismiss() }
        }
      }
        .alert(
          "記録を確認してください",
          isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
        ) {
          Button("閉じる", role: .cancel) { error = nil }
        } message: {
          Text(error ?? "")
        }
    }.presentationDetents([.large]).presentationDragIndicator(.visible).interactiveDismissDisabled(
      dirty)
  }
  func load(_ key: String) {
    draft = store.record(key) ?? SkinRecord(date: key)
    sleep = Double(draft.sleep) ?? 7
    care = draft.care ?? .unrecorded
    spots = draft.acneSpots ?? []
    selectedSpot = spots.first?.id
    baseline = snapshot
  }
  func carrySpots() {
    let ids = Set(spots.map(\.id))
    let previous = store.state.previousSpots(before: draft.date).filter { !ids.contains($0.id) }
    spots.append(contentsOf: previous)
    selectedSpot = previous.first?.id
    SkinsStyle.feedback()
  }
  func save() {
    let record = snapshot
    if let message = record.validationMessage {
      error = message
      return
    }
    if store.commit({ try $0.upsert(record) }) {
      SkinsStyle.feedback()
      onSave(record.date)
      dismiss()
    }
  }
}
