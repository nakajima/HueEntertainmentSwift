//
//  Session+Control.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation

@available(iOS 13.0, *)
public extension HueSession {
  func on(colors: [String]) {
    guard let area, let channels = area.channels, let connection else {
      return
    }

    var channelColors: [UInt8: String] = [:]
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

    var channelColors: [UInt8: String] = [:]
    for channel in channels {
      channelColors[channel.channel_id] = "000000"
    }

    let message = Message(area: area, channelColors: channelColors)
    connection.send(content: message.data, completion: .idempotent)
  }
}
