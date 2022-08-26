//
//  HueSession+Settings.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation

@available(iOS 14.0, *)
public extension HueSession {
	struct Settings {
		/// Always force full brightness for lights instead of calculated values.
		public var forceFullBrightness: Bool = false
	}

	static var settings = Settings()
}
