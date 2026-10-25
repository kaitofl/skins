import SkinsCore
import SwiftUI

struct ShelfView: View {
  @Environment(AppStore.self) private var store
  @ViewState private var selected: Product?
  @ViewState private var adding = false
  func stepNumber(_ product: Product) -> String {
    let items = store.state.products.filter { $0.time == product.time }
    let index = items.firstIndex { $0.id == product.id } ?? 0
    if let a = items.firstIndex(where: { $0.name.contains("アゼライン酸") }),
      let b = items.firstIndex(where: { $0.name.contains("レチナール") }), b == a + 1,
      Set(items[a].days).isDisjoint(with: items[b].days)
    {
      return String(format: "%02d", index + 1 - (index >= b ? 1 : 0))
    }
    return String(format: "%02d", index + 1)
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        AppHeader()
        ForEach(CareTime.allCases, id: \.self) { time in
          VStack(alignment: .leading, spacing: 14) {
            Label(time.title, systemImage: time.symbol).font(.title3.weight(.medium))
              .foregroundStyle(SkinsStyle.ink)
            ScrollView(.horizontal) {
              HStack(alignment: .bottom, spacing: 12) {
                ForEach(store.state.products.filter { $0.time == time }) { product in
                  Button {
                    selected = product
                    SkinsStyle.feedback()
                  } label: {
                    VStack(spacing: 8) {
                      Text(stepNumber(product)).font(.caption.monospacedDigit()).foregroundStyle(
                        SkinsStyle.muted
                      ).frame(maxWidth: .infinity, alignment: .leading)
                      ProductArt(product: product)
                      Text(product.brand.uppercased()).font(.caption.weight(.medium)).lineLimit(1)
                      Text(product.type).font(.caption).foregroundStyle(SkinsStyle.muted)
                      Text(product.daysLabel).font(.caption2).foregroundStyle(SkinsStyle.muted)
                        .lineLimit(2)
                    }.frame(width: 105).foregroundStyle(SkinsStyle.ink).padding(.bottom, 16)
                      .background(alignment: .bottom) {
                        Rectangle().fill(SkinsStyle.line).frame(height: 3).shadow(
                          color: SkinsStyle.ink.opacity(0.1), radius: 4, y: 4)
                      }
                  }.buttonStyle(.plain).accessibilityLabel(
                    "\(product.name)、\(product.daysLabel)、詳細を開く")
                }
              }.padding(.bottom, 8)
            }.scrollIndicators(.hidden)
          }
        }
        Button {
          adding = true
        } label: {
          Label("アイテムを追加", systemImage: "plus").font(.subheadline).frame(
            maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered).padding(.top, 6)
      }.padding(22)
    }.background(.white).navigationTitle("")
      .sheet(item: $selected) { product in ProductSheet(product: product) }
      .sheet(isPresented: $adding) {
        ProductEditor(product: Product(id: Int(Date().timeIntervalSince1970 * 1000), name: ""))
      }
  }
}
