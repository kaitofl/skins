import SkinsCore
import SwiftUI

struct ShelfView: View {
  @Environment(AppStore.self) private var store
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Namespace private var reorderNamespace
  @ViewState private var selected: Product?
  @ViewState private var adding = false

  private var columns: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 4 }

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

  private func reorder(_ id: Int, to target: Int) -> Bool {
    var moved = false
    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
      moved = store.moveProduct(id, to: target)
    }
    if moved { SkinsStyle.feedback() }
    return moved
  }

  private func moveAdjacent(_ product: Product, by offset: Int) {
    let items = store.state.products.filter { $0.time == product.time }
    guard let index = items.firstIndex(where: { $0.id == product.id }),
      items.indices.contains(index + offset)
    else { return }
    _ = reorder(product.id, to: items[index + offset].id)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 28) {
        AppHeader().padding(.horizontal, 22).padding(.top, 8)
        ForEach(CareTime.allCases, id: \.self) { time in
          let products = store.state.products.filter { $0.time == time }
          let starts = Array(stride(from: 0, to: products.count, by: columns))
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Label(time.title, systemImage: time.symbol)
                .font(.title3.weight(.medium))
                .foregroundStyle(SkinsStyle.ink)
                .accessibilityAddTraits(.isHeader)
              Spacer(minLength: 8)
              Text("長押しで並べ替え").font(.caption).foregroundStyle(SkinsStyle.muted)
            }.padding(.horizontal, 22)
            ForEach(starts, id: \.self) { start in
              ShelfRow(
                products: Array(products[start..<min(start + columns, products.count)]),
                columns: columns, stepNumber: stepNumber, reorderNamespace: reorderNamespace,
                onMove: reorder, onMoveAdjacent: moveAdjacent,
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
  let reorderNamespace: Namespace.ID
  let onMove: (Int, Int) -> Bool
  let onMoveAdjacent: (Product, Int) -> Void
  let onSelect: (Product) -> Void
  private let artHeight: CGFloat = 132
  private let numberHeight: CGFloat = 28
  private let topInset: CGFloat = 12

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      ForEach(0..<columns, id: \.self) { column in
        if column < products.count {
          let product = products[column]
          ShelfSlot(
            product: product, step: stepNumber(product), artHeight: artHeight,
            numberHeight: numberHeight, reorderNamespace: reorderNamespace,
            onSelect: { onSelect(product) }, onMove: onMove,
            onMoveAdjacent: { onMoveAdjacent(product, $0) })
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

/// Native dragging starts with a long press. Commit only on a successful drop;
/// cancelling a drag leaves both the visible order and saved data untouched.
private struct ShelfSlot: View {
  let product: Product
  let step: String
  let artHeight: CGFloat
  let numberHeight: CGFloat
  let reorderNamespace: Namespace.ID
  let onSelect: () -> Void
  let onMove: (Int, Int) -> Bool
  let onMoveAdjacent: (Int) -> Void
  @ViewState private var targeted = false

  var body: some View {
    Button(action: onSelect) {
      ShelfItem(product: product, step: step, artHeight: artHeight, numberHeight: numberHeight)
        .matchedGeometryEffect(id: product.id, in: reorderNamespace)
    }
    .buttonStyle(.plain).frame(maxWidth: .infinity).contentShape(Rectangle())
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(targeted ? SkinsStyle.accent.opacity(0.7) : .clear, lineWidth: 2)
        .padding(-3).allowsHitTesting(false)
    }
    .draggable("skins-shelf-product:\(product.id)") {
      ProductArt(product: product, height: 132, grounded: true)
        .frame(width: 90).padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
    .dropDestination(for: String.self) { items, _ in
      guard items.count == 1, let value = items.first,
        value.hasPrefix("skins-shelf-product:"),
        let id = Int(value.dropFirst("skins-shelf-product:".count))
      else { return false }
      targeted = false
      return onMove(id, product.id)
    } isTargeted: {
      targeted = $0
    }
    .accessibilityLabel("\(product.name)、\(product.daysLabel)、詳細を開く")
    .accessibilityHint("長押しして同じ時間の棚の中でドラッグすると順番を変更できます")
    .accessibilityAction(named: Text("前に移動")) { onMoveAdjacent(-1) }
    .accessibilityAction(named: Text("後ろに移動")) { onMoveAdjacent(1) }
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
          Text(product.daysLabel.replacingOccurrences(of: "・", with: ""))
            .font(.caption2.weight(.medium))
            .foregroundStyle(SkinsStyle.accent)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(SkinsStyle.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(SkinsStyle.accent.opacity(0.14)))
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
