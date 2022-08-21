//
//  XYBrightness.swift
//
//
//  Ported from https://github.com/benknight/hue-python-rgb-converter/blob/f73a4ecb5dd0c5050edbfc460a696da685d441d7/rgbxy/__init__.py
//

import Foundation

public struct XYBrightness {
  struct Gamut {
    var points: [CGPoint]

    var red: CGPoint {
      self.points[0]
    }

    var lime: CGPoint {
      self.points[1]
    }

    var blue: CGPoint {
      self.points[2]
    }
  }

  // LivingColors Iris, Bloom, Aura, LightStrips
  let GamutA = Gamut(points: [
    CGPoint(x: 0.704, y: 0.296),
    CGPoint(x: 0.2151, y: 0.7106),
    CGPoint(x: 0.138, y: 0.08),
  ])

  // Hue A19 bulbs
  let GamutB = Gamut(points: [
    CGPoint(x: 0.675, y: 0.322),
    CGPoint(x: 0.4091, y: 0.518),
    CGPoint(x: 0.167, y: 0.04),
  ])

  // Hue BR30, A19 (Gen 3), Hue Go, LightStrips plus
  let GamutC = Gamut(points: [
    CGPoint(x: 0.692, y: 0.308),
    CGPoint(x: 0.17, y: 0.7),
    CGPoint(x: 0.153, y: 0.048),
  ])

  let GamutD = Gamut(points: [
    CGPoint(x: 1.0, y: 0),
    CGPoint(x: 0.0, y: 1.0),
    CGPoint(x: 0.0, y: 0.0),
  ])

  var x: Double = 0
  var y: Double = 0
  var brightness: Double = 0

  init(red: Double, green: Double, blue: Double) {
    let red = (red > 0.04045) ? pow((red + 0.055) / (1.0 + 0.055), 2.4) : (red / 12.92)
    let green = (green > 0.04045) ? pow((green + 0.055) / (1.0 + 0.055), 2.4) : (green / 12.92)
    let blue = (blue > 0.04045) ? pow((blue + 0.055) / (1.0 + 0.055), 2.4) : (blue / 12.92)

    let X = red * 0.649926 + green * 0.103455 + blue * 0.197109
    let Y = red * 0.234327 + green * 0.743075 + blue * 0.022598
    let Z = red * 0.0000000 + green * 0.053077 + blue * 1.035763

    let x = X / (X + Y + Z)
    let y = Y / (X + Y + Z)
    self.brightness = Y

    let calculatedPoint = CGPoint(x: x, y: y)
    if self.checkPointInLampsReach(calculatedPoint) {
      self.x = x
      self.y = y
    } else {
      let point = self.getClosestPointToPoint(calculatedPoint)
      self.x = point.x
      self.y = point.y
    }
  }

  var gamut: Gamut {
    return self.GamutC
  }

  var bytes: [UInt8] {
    var x = x.isNaN ? UInt16(0) : UInt16(x * 65535).byteSwapped
    var y = y.isNaN ? UInt16(0) : UInt16(y * 65535).byteSwapped
    var brightness = brightness.isNaN ? UInt16(0) : UInt16(brightness * 65535).byteSwapped

    return withUnsafeBytes(of: &x, Array.init) + withUnsafeBytes(of: &y, Array.init) + withUnsafeBytes(of: &brightness, Array.init)
  }

  func crossProduct(_ p1: CGPoint, _ p2: CGPoint) -> Double {
    return (p1.x * p2.y - p1.y * p2.x)
  }

  func checkPointInLampsReach(_ point: CGPoint) -> Bool {
    let v1 = CGPoint(x: gamut.lime.x - self.gamut.red.x, y: self.gamut.lime.y - self.gamut.red.y)
    let v2 = CGPoint(x: gamut.blue.x - self.gamut.red.x, y: self.gamut.blue.y - self.gamut.red.y)
    let q = CGPoint(x: point.x - self.gamut.red.x, y: point.y - self.gamut.red.y)
    let s = self.crossProduct(q, v2) / self.crossProduct(v1, v2)
    let t = self.crossProduct(v1, q) / self.crossProduct(v1, v2)
    return (s >= 0.0) && (t >= 0) && (s + t <= 1.0)
  }

  func getClosestPointToLine(_ A: CGPoint, _ B: CGPoint, _ P: CGPoint) -> CGPoint {
    let AP = CGPoint(x: P.x - A.x, y: P.y - A.y)
    let AB = CGPoint(x: B.x - A.x, y: B.y - A.y)
    let ab2 = AB.x * AB.x + AB.y * AB.y
    let ap_ab = AP.x * AB.x + AP.y * AB.y
    var t = ap_ab / ab2

    if t < 0.0 {
      t = 0.0
    } else if t > 1.0 {
      t = 1.0
    }

    return CGPoint(x: A.x + AB.x * t, y: A.y + AB.y * t)
  }

  func getClosestPointToPoint(_ point: CGPoint) -> CGPoint {
    // Color is unreproducible, find the closest point on each line in the CIE 1931 'triangle'.
    let pAB = self.getClosestPointToLine(self.gamut.red, self.gamut.lime, point)
    let pAC = self.getClosestPointToLine(self.gamut.blue, self.gamut.red, point)
    let pBC = self.getClosestPointToLine(self.gamut.lime, self.gamut.blue, point)

    // Get the distances per point and see which point is closer to our Point.
    let dAB = self.getDistanceBetweenTwoPoints(point, pAB)
    let dAC = self.getDistanceBetweenTwoPoints(point, pAC)
    let dBC = self.getDistanceBetweenTwoPoints(point, pBC)
//
    var lowest = dAB
    var closest_point = pAB
//
    if dAC < lowest {
      lowest = dAC
      closest_point = pAC
    }
//
    if dBC < lowest {
      lowest = dBC
      closest_point = pBC
    }
//
//    # Change the xy value to a value which is within the reach of the lamp.
    let cx = closest_point.x
    let cy = closest_point.y

    return CGPoint(x: cx, y: cy)
  }

  func getDistanceBetweenTwoPoints(_ one: CGPoint, _ two: CGPoint) -> Double {
    let dx = one.x - two.x
    let dy = one.y - two.y
    return sqrt(dx * dx + dy * dy)
  }
}
