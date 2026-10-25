import SkinsCore
import SwiftUI

struct ProductSheet: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let product: Product
  @ViewState private var editing = false
  @ViewState private var dates = ProductJournal()
  @ViewState private var datesLoaded = false
  var current: Product { store.state.products.first { $0.id == product.id } ?? product }
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(spacing: 12) {
            ProductArt(product: current, height: 190)
            Text(current.brand.uppercased()).font(.caption).tracking(2).foregroundStyle(
              SkinsStyle.muted)
            Text(current.name).font(.title3.weight(.medium)).multilineTextAlignment(.center)
            Text("\(current.type) · \(current.time.title) · \(current.daysLabel)").font(
              .subheadline
            ).foregroundStyle(SkinsStyle.muted)
          }.frame(maxWidth: .infinity)
          Divider()
          SectionCaption(title: "マイ記録")
          optionalDate("購入日", keyPath: \.purchasedAt)
          optionalDate("使い始めた日", keyPath: \.startedAt)
          if let start = DayKey.date(dates.startedAt) {
            Text(
              "使い始めて \((DayKey.calendar.dateComponents([.day],from:start,to:Date()).day ?? 0)+1)日"
            ).font(.subheadline).foregroundStyle(SkinsStyle.muted)
          }
          if let info = store.info(current) {
            Divider()
            SectionCaption(title: "特徴")
            Text(info.features).font(.body).lineSpacing(5)
            SectionCaption(title: "主な成分")
            ForEach(info.ingredients.indices, id: \.self) { index in
              let item = info.ingredients[index]
              HStack {
                Text(item.first ?? "")
                Spacer()
                Text(item.last ?? "").foregroundStyle(SkinsStyle.muted)
              }.font(.subheadline)
            }
            SectionCaption(title: "こんな人におすすめ")
            ForEach(info.recommend, id: \.self) { Text("・" + $0).font(.subheadline) }
            if let url = URL(string: info.source) {
              Link("公式の商品情報 ↗", destination: url).font(.subheadline)
            }
          } else if let source = current.sourceUrl, let url = URL(string: source) {
            Link("公式の商品情報 ↗", destination: url)
          }
          Button("登録内容を修正") {
            SkinsStyle.feedback()
            editing = true
          }.frame(maxWidth: .infinity, minHeight: 48)
            .buttonStyle(.bordered)
        }.padding(24).foregroundStyle(SkinsStyle.ink)
      }.navigationTitle("アイテム").navigationBarTitleDisplayModeCompat()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("閉じる") {
              SkinsStyle.feedback()
              dismiss()
            }
          }
        }
    }.presentationDetents([.large]).presentationDragIndicator(.visible)
      .onAppear {
        dates = store.journal(current)
        datesLoaded = true
      }
      .sheet(
        isPresented: $editing,
        onDismiss: {
          if !store.state.products.contains(where: { $0.id == product.id }) { dismiss() }
        }
      ) { ProductEditor(product: current) }
  }
  func optionalDate(_ title: String, keyPath: WritableKeyPath<ProductJournal, String>) -> some View
  {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(
        title,
        isOn: Binding(
          get: { !dates[keyPath: keyPath].isEmpty },
          set: { enabled in
            var next = dates
            next[keyPath: keyPath] = enabled ? DayKey.today : ""
            commitDates(next)
          })
      ).font(.subheadline)
      if let date = DayKey.date(dates[keyPath: keyPath]) {
        DatePicker(
          title,
          selection: Binding(
            get: { date },
            set: { value in
              var next = dates
              next[keyPath: keyPath] = DayKey.string(value)
              commitDates(next)
            }), in: ...Date(), displayedComponents: .date
        ).labelsHidden()
      }
    }
  }
  func commitDates(_ next: ProductJournal) {
    guard datesLoaded else { return }
    if store.commit({ $0.productJournals[current.journalKey] = next }) { dates = next }
  }
}
extension View {
  @ViewBuilder func navigationBarTitleDisplayModeCompat() -> some View {
    #if os(iOS)
      self.navigationBarTitleDisplayMode(.inline)
    #else
      self
    #endif
  }
}
struct ProductEditor: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @ViewState var product: Product
  @ViewState private var confirmDelete = false
  var existing: Bool { store.state.products.contains { $0.id == product.id } }
  var body: some View {
    NavigationStack {
      Form {
        Section("アイテム") {
          TextField("商品名", text: $product.name)
          TextField("ブランド", text: $product.brand)
          Picker("種類", selection: $product.type) {
            ForEach(
              Array(
                Set([
                  "クレンジング", "洗顔料", "化粧水", "美容液", "乳液", "クリーム", "日焼け止め", "化粧下地", "BBクリーム", "パウダー",
                  "その他", product.type,
                ])
              ).sorted(), id: \.self
            ) { Text($0).tag($0) }
          }
          Picker("使う時間", selection: $product.time) {
            ForEach(CareTime.allCases, id: \.self) { Text($0.title).tag($0) }
          }
        }
        Section("使う日") {
          Toggle(
            "必要な日に使う",
            isOn: Binding(get: { product.asNeeded == true }, set: { product.asNeeded = $0 }))
          if product.asNeeded != true {
            ForEach(0..<7, id: \.self) { day in
              Toggle(
                DayKey.weekdays[day] + "曜日",
                isOn: Binding(
                  get: { product.days.contains(day) },
                  set: { on in
                    product.days.removeAll { $0 == day }
                    if on {
                      product.days.append(day)
                      product.days.sort()
                    }
                  }))
            }
          }
        }
        if existing {
          Section {
            Button("棚から外す", role: .destructive) {
              SkinsStyle.feedback()
              confirmDelete = true
            }
          }
        }
      }.sensoryFeedback(.selection, trigger: product)
        .navigationTitle(existing ? "アイテムを編集" : "アイテムを追加").navigationBarTitleDisplayModeCompat()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("キャンセル") {
              SkinsStyle.feedback()
              dismiss()
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("保存") {
              SkinsStyle.feedback()
              if store.saveProduct(product) {
                SkinsStyle.feedback()
                dismiss()
              }
            }.disabled(
              product.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (product.days.isEmpty && product.asNeeded != true))
          }
        }
        .confirmationDialog(
          "このアイテムを棚から外しますか？", isPresented: $confirmDelete, titleVisibility: .visible
        ) {
          Button("棚から外す", role: .destructive) {
            SkinsStyle.feedback()
            if store.commit({ $0.products.removeAll { $0.id == product.id } }) { dismiss() }
          }
        }
    }.presentationDetents([.large]).presentationDragIndicator(.visible)
  }
}
