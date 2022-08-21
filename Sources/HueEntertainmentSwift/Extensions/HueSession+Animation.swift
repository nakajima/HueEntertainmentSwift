//
//  File.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation

@available(iOS 14.0, *)
extension HueSession {
	@objc func fireTimer() {
		if updates.isEmpty {
			return
		}

		for update in updates {
			update.apply(self)
		}

		updates.removeAll { $0.animation.isComplete }
	}
}
