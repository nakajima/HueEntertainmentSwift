//
//  Message.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import SwiftUI

/// A UDP message used by the hue entertainment API (v2).
@available(iOS 14.0, *)
public struct Message {
	public var area: HueEntertainmentArea
	public var channelColors: [UInt8: Color]
	public var forcedBrightness: Double?

	/// Returns data suitable for sending over UDP to the bridge via `session.connection`. If you
	/// don't want to use `session.on(colors:, ramp:)`, you can create a message manually.
	public var data: Data {
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

		area.id.data(using: .utf8)!.withUnsafeBytes { bytes.append(contentsOf: $0) }

		for (i, color) in channelColors {
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
