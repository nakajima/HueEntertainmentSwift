//
//  Message.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
public struct Message {
  var area: HueEntertainmentArea
  var channelColors: [UInt8: Color]
  var forcedBrightness: Double?

  var data: Data {
    var bytes: [UInt8] = []

    // Protocol
    bytes.append(contentsOf: "HueStream".data(using: .utf8)!)

    // Version 2.0
    bytes.append(contentsOf: [0x02, 0x00])

    // Sequence number 1 (ignored)
    bytes.append(0x01)

    // Reserved (write 0’s)
    bytes.append(contentsOf: [0x00, 0x00])

    // color mode xy brightness
    bytes.append(0x01)

    // Reserved, write 0’s
    bytes.append(0x00)

    self.area.id.data(using: .utf8)!.withUnsafeBytes { bytes.append(contentsOf: $0) }

    for (i, color) in self.channelColors {
      let channelData = channelData(id: i, color: color)
      bytes.append(contentsOf: channelData)
    }

    return Data(bytes)
  }

  func channelData(id: UInt8, color: Color) -> [UInt8] {
    let xyBrightness = XYBrightness(color: color, forcedBrightness: forcedBrightness)

    return [id] + xyBrightness.bytes
  }
}
