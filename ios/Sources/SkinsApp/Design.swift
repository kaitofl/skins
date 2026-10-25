import SkinsCore
import SwiftUI

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

// Explicit type alias avoids the State macro overload in newer SDKs.
typealias ViewState<Value> = SwiftUI.State<Value>

enum SkinsStyle {
  static let ink = Color(red: 0.26, green: 0.36, blue: 0.46)
  static let accent = Color(red: 0.42, green: 0.53, blue: 0.65)
  static let muted = Color(red: 0.49, green: 0.58, blue: 0.68)
  static let surface = Color(red: 0.96, green: 0.97, blue: 0.99)
  static let line = Color(red: 0.87, green: 0.90, blue: 0.94)
  static func feedback() {
    #if os(iOS)
      UISelectionFeedbackGenerator().selectionChanged()
    #endif
  }
}
extension SkinMood {
  var color: Color {
    switch self {
    case .good: Color(red: 0.43, green: 0.61, blue: 0.53)
    case .normal: SkinsStyle.accent
    case .uneasy: Color(red: 0.73, green: 0.48, blue: 0.51)
    case .dry: Color(red: 0.69, green: 0.57, blue: 0.41)
    }
  }
}
extension SpotStatus {
  var color: Color {
    switch self {
    case .new: Color(red: 0.70, green: 0.59, blue: 0.44)
    case .worse: Color(red: 0.75, green: 0.49, blue: 0.51)
    case .better: Color(red: 0.47, green: 0.65, blue: 0.60)
    }
  }
}
struct SectionCaption: View {
  let title: String
  var body: some View {
    Text(title).font(.headline).foregroundStyle(SkinsStyle.ink).frame(
      maxWidth: .infinity, alignment: .leading)
  }
}
struct AppHeader: View {
  var body: some View {
    Text("skins").font(.system(size: 42, weight: .light, design: .rounded)).tracking(-2)
      .foregroundStyle(SkinsStyle.ink).frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel("Skins")
  }
}
private struct ProductImageFrame: Decodable, Sendable {
  let w: Double
  let h: Double
  let x: Double
  let y: Double
  let bw: Double
  let bh: Double
}
struct ProductArt: View {
  private static let bounds =
    (try? JSONDecoder().decode(
      [String: ProductImageFrame].self, from: AppStore.resource("image-bounds"))) ?? [:]
  let product: Product
  var height: CGFloat = 140
  var grounded = false
  var asset: String {
    product.asset ?? String([5102: 5001, 5103: 5002, 5106: 5004][product.id] ?? product.id)
  }
  var body: some View {
    Group {
      #if SWIFT_PACKAGE
        let url = Bundle.module.url(
          forResource: asset, withExtension: "png", subdirectory: "Content/Products")
      #else
        let url = Bundle.main.url(
          forResource: asset, withExtension: "png", subdirectory: "Content/Products")
      #endif
      #if os(iOS)
        if let path = url?.path, let image = UIImage(contentsOfFile: path) {
          cropped(Image(uiImage: image))
        } else {
          Image(systemName: "bubbles.and.sparkles").font(.largeTitle).foregroundStyle(
            SkinsStyle.muted)
        }
      #else
        if let path = url?.path, let image = NSImage(contentsOfFile: path) {
          cropped(Image(nsImage: image))
        } else {
          Image(systemName: "bubbles.and.sparkles").font(.largeTitle).foregroundStyle(
            SkinsStyle.muted)
        }
      #endif
    }.frame(height: height).accessibilityHidden(true)
  }
  @ViewBuilder private func cropped(_ image: Image) -> some View {
    if let b = Self.bounds[asset] {
      GeometryReader { geo in
        let scale = min(geo.size.width / b.bw, geo.size.height / b.bh)
        image.resizable().frame(width: b.w * scale, height: b.h * scale)
          .offset(
            x: (geo.size.width - b.bw * scale) / 2 - b.x * scale,
            y: (geo.size.height - b.bh * scale) / (grounded ? 1 : 2) - b.y * scale)
      }.clipped()
    } else {
      image.resizable().scaledToFit().frame(
        maxWidth: .infinity, maxHeight: .infinity, alignment: grounded ? .bottom : .center)
    }
  }
}
struct PrimaryButton: View {
  let title: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
    }.buttonStyle(.plain).background(SkinsStyle.accent, in: RoundedRectangle(cornerRadius: 14))
      .foregroundStyle(.white)
  }
}
struct ChoiceGrid<Value: Hashable>: View {
  let values: [Value]
  @Binding var selection: Value
  let label: (Value) -> String
  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
      ForEach(values, id: \.self) { value in
        Button {
          selection = value
          SkinsStyle.feedback()
        } label: {
          Text(label(value)).font(.subheadline).frame(maxWidth: .infinity, minHeight: 46).padding(
            .horizontal, 4)
        }.buttonStyle(.plain).foregroundStyle(
          selection == value ? SkinsStyle.ink : SkinsStyle.muted
        )
        .background(
          selection == value ? SkinsStyle.accent.opacity(0.13) : .white,
          in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12).stroke(
            selection == value ? SkinsStyle.accent : SkinsStyle.line)
        )
        .accessibilityAddTraits(selection == value ? .isSelected : [])
      }
    }
  }
}
