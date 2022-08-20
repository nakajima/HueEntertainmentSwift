//
//  Message.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation

// Very basic message that will set all lights in the entertainment
// area to the color passed (as a hex string, like "FF0000")
public struct Message {
  var area: HueEntertainmentArea
  var channelColors: [UInt8: String]

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

    // color mode RGB
    bytes.append(0x00)

    // Reserved, write 0’s
    bytes.append(0x00)

    self.area.id.data(using: .utf8)!.withUnsafeBytes { bytes.append(contentsOf: $0) }

    bytes.append(contentsOf: [0x00]) // channel ID 0
    bytes.append(contentsOf: [0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00]) // red

    for (i, color) in self.channelColors {
      let channelData = channelData(id: i, color: color)
      bytes.append(contentsOf: channelData)
    }

//    0x01, //channel ID 1
//
//    0x00, 0x00, 0x00, 0x00, 0xff, 0xff //blue
    return Data(bytes)
  }

  func channelData(id: UInt8, color: String) -> [UInt8] {
    let bytes = color.hexToBytes
    return [id] + [
      bytes[0], bytes[0],
      bytes[1], bytes[1],
      bytes[2], bytes[2],
    ]
  }
}
