//
//  ChannelUpdate.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct AreaUpdate {
  var area: HueEntertainmentArea
  var channelColors: [UInt8: Color]
  var animation: Animation

  func apply(_ session: HueSession) {
    let message = Message(area: area, channelColors: channelColors, forcedBrightness: animation.value())
    session.connection?.send(content: message.data, completion: .idempotent)
  }
}
