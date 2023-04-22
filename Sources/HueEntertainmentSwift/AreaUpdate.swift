//
//  AreaUpdate.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
public struct AreaUpdate {
	var channelColors: [UInt8: Color]
	var animation: Animation

	func apply(_ session: HueSession) {
		guard let area = session.area, let connection = session.connection else {
			return
		}

		let message = Message(area: area, channelColors: channelColors, forcedBrightness: animation.value())
		connection.send(content: message.data, completion: .idempotent)
	}
}
