import SkinsCore
import SwiftUI

struct FaceOutline: Shape {
  func path(in rect: CGRect) -> Path {
    let sx = rect.width / 240
    let sy = rect.height / 280
    var p = Path()
    p.move(to: CGPoint(x: 120, y: 18))
    p.addCurve(
      to: CGPoint(x: 41, y: 103), control1: CGPoint(x: 67, y: 18), control2: CGPoint(x: 40, y: 52))
    p.addLine(to: CGPoint(x: 49, y: 168))
    p.addCurve(
      to: CGPoint(x: 120, y: 247), control1: CGPoint(x: 54, y: 207),
      control2: CGPoint(x: 93, y: 247))
    p.addCurve(
      to: CGPoint(x: 191, y: 168), control1: CGPoint(x: 147, y: 247),
      control2: CGPoint(x: 186, y: 207))
    p.addLine(to: CGPoint(x: 199, y: 103))
    p.addCurve(
      to: CGPoint(x: 120, y: 18), control1: CGPoint(x: 200, y: 52), control2: CGPoint(x: 173, y: 18)
    )
    p.closeSubpath()
    return p.applying(CGAffineTransform(scaleX: sx, y: sy))
  }
}
struct FaceFeatures: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    for x: CGFloat in [69, 146] {
      p.move(to: CGPoint(x: x, y: 120))
      p.addQuadCurve(to: CGPoint(x: x + 25, y: 120), control: CGPoint(x: x + 12, y: 130))
      p.move(to: CGPoint(x: x - 3, y: 101))
      p.addQuadCurve(to: CGPoint(x: x + 28, y: 99), control: CGPoint(x: x + 13, y: 91))
    }
    p.move(to: CGPoint(x: 120, y: 126))
    p.addLine(to: CGPoint(x: 115, y: 154))
    p.addQuadCurve(to: CGPoint(x: 127, y: 154), control: CGPoint(x: 120, y: 160))
    p.move(to: CGPoint(x: 103, y: 185))
    p.addQuadCurve(to: CGPoint(x: 137, y: 185), control: CGPoint(x: 120, y: 197))
    p.move(to: CGPoint(x: 83, y: 232))
    p.addLine(to: CGPoint(x: 83, y: 261))
    p.move(to: CGPoint(x: 157, y: 232))
    p.addLine(to: CGPoint(x: 157, y: 261))
    return p.applying(CGAffineTransform(scaleX: rect.width / 240, y: rect.height / 280))
  }
}
struct FaceMap: View {
  @Binding var spots: [AcneSpot]
  @Binding var selectedID: String?
  var selectedIndex: Int? { spots.firstIndex { $0.id == selectedID } }
  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("自分の右")
        Spacer()
        Text("自分の左")
      }.font(.caption).foregroundStyle(SkinsStyle.muted)
      GeometryReader { geo in
        ZStack {
          FaceOutline().fill(SkinsStyle.surface)
          FaceOutline().stroke(SkinsStyle.muted.opacity(0.5), lineWidth: 1.5)
          FaceFeatures().stroke(
            SkinsStyle.muted.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }.contentShape(Rectangle()).gesture(
          SpatialTapGesture().onEnded { value in
            let x = value.location.x / geo.size.width * 100
            let y = value.location.y / geo.size.height * 100
            guard AcneSpot.isOnFace(x: x, y: y) else { return }
            let spot = AcneSpot(x: x, y: y)
            spots.append(spot)
            selectedID = spot.id
            SkinsStyle.feedback()
          })
        ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
          Button {
            SkinsStyle.feedback()
            selectedID = spot.id
            SkinsStyle.feedback()
          } label: {
            Text("\(index+1)").font(.caption.weight(.semibold)).frame(width: 30, height: 30)
              .background(spot.status?.color ?? SkinsStyle.muted, in: Circle()).foregroundStyle(
                .white
              ).overlay(Circle().stroke(.white, lineWidth: 2)).padding(4).overlay(
                Circle().stroke(
                  selectedID == spot.id ? spot.status?.color ?? SkinsStyle.muted : .clear,
                  lineWidth: 2)
              ).frame(width: 44, height: 44)
          }.buttonStyle(SkinsPressStyle()).position(
            x: geo.size.width * spot.x / 100, y: geo.size.height * spot.y / 100
          ).accessibilityLabel("\(index+1)番、\(spot.area)、\(spot.status?.title ?? "状態未選択")")
        }
      }.frame(width: 257, height: 300)
      if let index = selectedIndex {
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            Text("\(index+1) · \(spots[index].area)").font(.headline)
            Spacer()
            Button("削除", role: .destructive) {
              SkinsStyle.feedback()
              spots.remove(at: index)
              selectedID = spots.first?.id
            }.font(.subheadline)
          }
          ForEach(SpotStatus.allCases, id: \.self) { status in
            Button {
              SkinsStyle.feedback()
              spots[index].status = status
              SkinsStyle.feedback()
            } label: {
              HStack {
                Circle().fill(status.color).frame(width: 8, height: 8)
                Text(status.title)
                Spacer()
                if spots[index].status == status { Image(systemName: "checkmark") }
              }.font(.subheadline).frame(minHeight: 40)
            }.buttonStyle(SkinsPressStyle()).accessibilityAddTraits(
              spots[index].status == status ? .isSelected : [])
          }
        }.padding(16).background(SkinsStyle.surface, in: RoundedRectangle(cornerRadius: 14))
      } else {
        Text("顔をタップして、気になる場所に印をつけましょう。").font(.subheadline).foregroundStyle(SkinsStyle.muted)
      }
      Menu {
        ForEach(
          [
            ("おでこ", 50.0, 25.0), ("右頬", 29, 57), ("左頬", 71, 57), ("鼻", 50, 53), ("あご", 50, 81),
            ("フェイスライン", 27, 71),
          ], id: \.0
        ) { area, x, y in
          Button(area) {
            SkinsStyle.feedback()
            let spot = AcneSpot(x: x, y: y, area: area)
            spots.append(spot)
            selectedID = spot.id
          }
        }
      } label: {
        Label("場所を選んで追加", systemImage: "plus.circle").font(.subheadline).frame(minHeight: 44)
      }
    }.frame(maxWidth: 320).frame(maxWidth: .infinity)
  }
}
