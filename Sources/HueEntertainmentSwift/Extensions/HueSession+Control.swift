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
		guard let area = area, let channels = area.channels else {
			return
		}

		let colors = colors.isEmpty ? [Color.white] : colors.shuffled()

		var channelColors: [UInt8: Color] = [:]
		for (i, channel) in channels.enumerated() {
			channelColors[channel.channel_id] = colors[i % colors.count]
		}

		let update = AreaUpdate(channelColors: channelColors, animation: Animation(startAt: Date(), duration: ramp))
		updates.append(update)
	}

	/// Turns off lights in entertainment area.
	func off() {
		guard let area = area, let channels = area.channels, let connection = connection else {
			return
		}

		var channelColors: [UInt8: Color] = [:]
		for channel in channels {
			channelColors[channel.channel_id] = Color.clear
		}

		let message = Message.off(area: area)
		connection.send(content: message.data, completion: .idempotent)
	}
}
