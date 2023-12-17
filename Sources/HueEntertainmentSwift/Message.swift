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
	var area: HueEntertainmentArea
	var channelColors: [UInt8: Color]
	var forcedBrightness: Double?

	/// Returns data suitable for sending over UDP to the bridge via `session.connection`. If you
	/// don't want to use `session.on(colors:, ramp:)`, you can create a message manually.
	var data: Data

	public static func off(area: HueEntertainmentArea) -> Message {
		return Message(area: area, channelColors: [:])
	}

	init(area: HueEntertainmentArea, channelColors: [UInt8 : Color], forcedBrightness: Double? = nil) {
		self.area = area
		self.channelColors = channelColors
		self.forcedBrightness = forcedBrightness

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
			let xyBrightness = XYBrightness(color: color, forcedBrightness: forcedBrightness)
			bytes.append(contentsOf: [i] + xyBrightness.bytes)
		}

		self.data = Data(bytes)
	}

	mutating func off() {
		var bytes: [UInt8] = []

		// Protocol
		bytes.append(contentsOf: "HueStream".data(using: .utf8)!)

		// Version 2.0
		bytes.append(contentsOf: [0x02, 0x00])

		// Sequence number 1 (ignored)
		bytes.append(0x01)

		// Reserved (write 0’s)
		bytes.append(contentsOf: [0x00, 0x00])

		// color mode rgb brightness
		bytes.append(0x00)

		// Reserved, write 0’s
		bytes.append(0x00)

		area.id.data(using: .utf8)!.withUnsafeBytes { bytes.append(contentsOf: $0) }

		for (i, _) in channelColors {
			bytes.append(contentsOf: [i] + [255, 255, 255, 255, 255, 255])
		}

		self.data = Data(bytes)
	}
}
