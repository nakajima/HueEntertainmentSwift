//
//  Session+Control.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
public extension HueSession {
  func on(colors: [Color]) {
    guard let area, let channels = area.channels, let connection else {
      return
    }

    let colors = colors.isEmpty ? [Color.white] : colors.shuffled()

    var channelColors: [UInt8: Color] = [:]
    for (i, channel) in channels.enumerated() {
      channelColors[channel.channel_id] = colors[i % colors.count]
    }

    let message = Message(area: area, channelColors: channelColors)
    connection.send(content: message.data, completion: .idempotent)
  }

  func off() {
    guard let area, let channels = area.channels, let connection else {
      return
    }

    var channelColors: [UInt8: Color] = [:]
    for channel in channels {
      channelColors[channel.channel_id] = Color.black
    }

    let message = Message(area: area, channelColors: channelColors)
    connection.send(content: message.data, completion: .idempotent)
  }
}
