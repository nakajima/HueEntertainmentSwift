//
//  Session+Control.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import Network
import SwiftUI

@available(iOS 14.0, *)
public extension HueSession {
	/**
	 Turns on lights.

	 - Parameter colors: An array of ``SwiftUI.Color``s that will be randomly chosen for different lights in the entertainment area.
	 - Parameter ramp: The amount of time (in seconds) it should take for the light to reach its brightness
	 */

	func on(colors: [Color], ramp: Double = 0) {
		guard let area = area, let channels = area.channels, let connection else {
			return
		}

		let colors = colors.isEmpty ? [Color.white] : colors.shuffled()

		var channelColors: [UInt8: Color] = [:]
		for (i, channel) in channels.enumerated() {
			channelColors[channel.channel_id] = colors[i % colors.count]
		}

		let message = Message(area: area, channelColors: channelColors)

		print("ON MESSAGE")
		print([UInt8](message.data).debugDescription)

		connection.send(content: message.data, completion: .idempotent)
	}

	/// Turns off lights in entertainment area.
	func off() {
		guard let area, let connection, let channels = area.channels else {
			return
		}

		var channelColors: [UInt8: Color] = [:]
		for channel in channels {
			channelColors[channel.channel_id] = .black
		}

		let message = Message(area: area, channelColors: channelColors)

		print("OFF MESSAGE")
		print([UInt8](message.data).debugDescription)

		connection.send(content: message.data, completion: .idempotent)
	}
}
