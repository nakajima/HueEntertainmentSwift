//
//  File.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation

extension String {
	var hexToBytes: [UInt8] {
		var start = startIndex
		return stride(from: 0, to: count, by: 2).compactMap { _ in
			let end = index(after: start)
			defer { start = index(after: end) }
			return UInt8(self[start ... end], radix: 16)
		}
	}
}
