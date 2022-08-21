//
//  Animation.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation

enum AnimationCurve {
	case linear, easeIn, easeOut, easeInOut, custom((Double) -> (Double))

	func apply(_ x: Double) -> Double {
		switch self {
		case .linear:
			return x
		case .easeIn:
			return x * x * x * x * x
		case .easeOut:
			return 1 - pow(1 - x, 5)
		case .easeInOut:
			return x < 0.5 ? 16 * x * x * x * x * x : 1 - pow(-2 * x + 2, 5) / 2
		case let .custom(fn):
			return fn(x)
		}
	}
}

struct Animation {
	// When should this animation begin
	let startAt: Date

	// How long this animation should take (in seconds)
	let duration: Double

	// Tween it
	let curve: AnimationCurve

	init(startAt: Date, duration: Double, curve: AnimationCurve = .easeIn) {
		self.startAt = startAt
		self.duration = duration
		self.curve = curve
	}

	// What the current value of the animation should be (from 0.0 to 1.0)
	func value(at now: Date? = nil) -> Double {
		if duration == 0 {
			return 1.0
		}

		let now = now ?? Date()
		let delta = now.timeIntervalSince(startAt)
		let progress = min(1.0, delta / duration)
		return curve.apply(progress)
	}

	var isComplete: Bool {
		return value() >= 1
	}
}
