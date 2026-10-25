import CoreGraphics
import Foundation

// A pump bottle and cream jar, drawn in the same 24 pt stroke family as the tab symbols.
let output = CommandLine.arguments[1]
var box = CGRect(x: 0, y: 0, width: 24, height: 24)
let url = URL(fileURLWithPath: output) as CFURL
guard let context = CGContext(url, mediaBox: &box, nil) else { fatalError("Cannot create icon") }
context.beginPDFPage(nil)
context.setStrokeColor(CGColor(gray: 0, alpha: 1))
context.setLineWidth(1.5)
context.setLineCap(.round)
context.setLineJoin(.round)
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
  context.addPath(
    CGPath(
      roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r,
      transform: nil))
  context.strokePath()
}
func line(_ points: [CGPoint]) {
  guard let first = points.first else { return }
  context.move(to: first)
  for p in points.dropFirst() { context.addLine(to: p) }
  context.strokePath()
}
rect(2.5, 1.8, 9, 13.5, 2)
rect(4.7, 15.3, 4.6, 3.4, 0.6)
line([
  CGPoint(x: 7, y: 18.7), CGPoint(x: 7, y: 21.8), CGPoint(x: 13.3, y: 21.8),
  CGPoint(x: 13.3, y: 20.2),
])
rect(4.9, 6, 4.2, 4.8, 0.8)
rect(14, 1.8, 7.7, 8, 1.7)
rect(13.6, 9.8, 8.5, 2.6, 0.7)
line([CGPoint(x: 16.1, y: 5.5), CGPoint(x: 19.6, y: 5.5)])
context.endPDFPage()
context.closePDF()
