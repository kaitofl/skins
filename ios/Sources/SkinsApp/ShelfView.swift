import SkinsCore
import SwiftUI

struct ShelfView: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ViewState private var selected: Product?
  @ViewState private var adding = false

  private var columns: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 3 }

  private func stepNumber(_ product: Product) -> String {
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
      LazyVStack(alignment: .leading, spacing: 28) {
        AppHeader().padding(.horizontal, 22).padding(.top, 8)
        ForEach(CareTime.allCases, id: \.self) { time in
          let products = store.state.products.filter { $0.time == time }
          let starts = Array(stride(from: 0, to: products.count, by: columns))
          VStack(alignment: .leading, spacing: 8) {
            Label(time.title, systemImage: time.symbol)
              .font(.title3.weight(.medium))
              .foregroundStyle(SkinsStyle.ink)
              .padding(.horizontal, 22)
              .accessibilityAddTraits(.isHeader)
            ForEach(starts, id: \.self) { start in
              ShelfRow(
                products: Array(products[start..<min(start + columns, products.count)]),
                columns: columns, stepNumber: stepNumber,
                onSelect: { product in
                  selected = product
                  SkinsStyle.feedback()
                })
            }
            if products.isEmpty {
              Text("いつものアイテムを棚に並べましょう。")
                .font(.subheadline).foregroundStyle(SkinsStyle.muted)
                .padding(.horizontal, 22).padding(.vertical, 28)
            }
          }
        }
        Button {
          adding = true
        } label: {
          Label("アイテムを追加", systemImage: "plus")
            .font(.subheadline).frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered).padding(.horizontal, 22).padding(.bottom, 24)
      }.padding(.top, 14)
    }
    .background(.white).navigationTitle("")
    .sheet(item: $selected) { ProductSheet(product: $0) }
    .sheet(isPresented: $adding) {
      ProductEditor(product: Product(id: Int(Date().timeIntervalSince1970 * 1000), name: ""))
    }
  }
}

/// One continuous board for each row, including the empty slots of the final row.
private struct ShelfRow: View {
  let products: [Product]
  let columns: Int
  let stepNumber: (Product) -> String
  let onSelect: (Product) -> Void
  private let artHeight: CGFloat = 132
  private let numberHeight: CGFloat = 28
  private let topInset: CGFloat = 12

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      ForEach(0..<columns, id: \.self) { column in
        if column < products.count {
          let product = products[column]
          Button {
            onSelect(product)
          } label: {
            ShelfItem(
              product: product, step: stepNumber(product), artHeight: artHeight,
              numberHeight: numberHeight)
          }
          .buttonStyle(.plain)
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .accessibilityLabel("\(product.name)、\(product.daysLabel)、詳細を開く")
        } else {
          Color.clear.frame(maxWidth: .infinity).accessibilityHidden(true)
        }
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, topInset)
    .padding(.bottom, 8)
    .overlay(alignment: .top) {
      ShelfBoard()
        .frame(height: 9)
        .offset(y: topInset + numberHeight + 8 + artHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }
}

private struct ShelfItem: View {
  let product: Product
  let step: String
  let artHeight: CGFloat
  let numberHeight: CGFloat

  private var role: String {
    if product.name.localizedCaseInsensitiveContains("PDRN") { return "保湿美容液" }
    if product.name.contains("ビタミン") || product.name.contains("PORESTRIX") {
      return "ビタミンC美容液"
    }
    if product.name.contains("アゼライン酸") { return "アゼライン酸美容液" }
    if product.name.contains("レチナール") { return "レチナール美容液" }
    return product.type
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(step)
        .font(.system(size: 23, weight: .light, design: .rounded).monospacedDigit())
        .foregroundStyle(SkinsStyle.muted.opacity(0.85))
        .frame(
          maxWidth: .infinity, minHeight: numberHeight, maxHeight: numberHeight,
          alignment: .leading)
      ProductArt(product: product, height: artHeight, grounded: true)
        .shadow(color: SkinsStyle.ink.opacity(0.13), radius: 2, x: 2, y: 3)
        .background(alignment: .bottom) {
          Ellipse().fill(SkinsStyle.ink.opacity(0.15))
            .frame(width: product.type == "パウダー" ? 70 : 32, height: 5)
            .blur(radius: 2).offset(y: 2)
        }
        .padding(.top, 8)
      VStack(spacing: 4) {
        Text(product.brand.uppercased())
          .font(.caption.weight(.semibold))
          .foregroundStyle(SkinsStyle.ink)
          .lineLimit(1).minimumScaleFactor(0.85)
        Text(role)
          .font(.caption)
          .foregroundStyle(SkinsStyle.muted)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
        if product.days.count != 7 || product.asNeeded == true {
          Text(product.daysLabel)
            .font(.caption2)
            .foregroundStyle(SkinsStyle.accent)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .padding(.top, 22)
      .frame(maxWidth: .infinity, minHeight: 76, alignment: .top)
    }
  }
}

/// Whitewashed shelf: a lit top edge, a shaded front face, and a single cast shadow.
private struct ShelfBoard: View {
  var body: some View {
    VStack(spacing: 0) {
      LinearGradient(
        colors: [Color.white, Color(red: 0.94, green: 0.96, blue: 0.98)],
        startPoint: .top, endPoint: .bottom
      )
      .frame(height: 3)
      .overlay(alignment: .top) { Color.white.frame(height: 1) }
      LinearGradient(
        colors: [
          Color(red: 0.89, green: 0.92, blue: 0.95),
          Color(red: 0.80, green: 0.85, blue: 0.90),
        ],
        startPoint: .top, endPoint: .bottom)
    }
    .overlay {
      Canvas { context, size in
        for y in stride(from: CGFloat(4), to: size.height, by: 2) {
          var line = Path()
          line.move(to: CGPoint(x: 0, y: y))
          line.addLine(to: CGPoint(x: size.width, y: y))
          context.stroke(line, with: .color(SkinsStyle.ink.opacity(0.035)), lineWidth: 0.5)
        }
      }
    }
    .shadow(color: SkinsStyle.ink.opacity(0.15), radius: 4, x: 0, y: 5)
  }
}
