import AppKit
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1024,pixelsHigh:1024,bitsPerSample:8,samplesPerPixel:3,hasAlpha:false,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
NSColor(calibratedRed:0.94,green:0.96,blue:0.98,alpha:1).setFill();NSBezierPath(rect:NSRect(origin:.zero,size:NSSize(width:1024,height:1024))).fill()
let p=NSBezierPath();p.move(to:NSPoint(x:650,y:610));p.curve(to:NSPoint(x:360,y:600),controlPoint1:NSPoint(x:560,y:760),controlPoint2:NSPoint(x:300,y:730));p.curve(to:NSPoint(x:625,y:350),controlPoint1:NSPoint(x:265,y:425),controlPoint2:NSPoint(x:710,y:545));p.curve(to:NSPoint(x:310,y:325),controlPoint1:NSPoint(x:550,y:185),controlPoint2:NSPoint(x:340,y:210));p.lineWidth=38;p.lineCapStyle = .round;p.lineJoinStyle = .round
NSColor(calibratedRed:0.35,green:0.46,blue:0.58,alpha:1).setStroke();p.stroke()
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
