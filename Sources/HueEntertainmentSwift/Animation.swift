//
//  Animation.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation

struct Animation {
  // When should this animation begin
  let startAt: Date

  // How long this animation should take (in seconds)
  let duration: Double

  // What the current value of the animation should be (from 0.0 to 1.0)
  func value(at now: Date? = nil) -> Double {
    if self.duration == 0 {
      return 1.0
    }

    let now = now ?? Date()
    let delta = now.timeIntervalSince(self.startAt)
    return min(1.0, delta / self.duration)
  }

  var isComplete: Bool {
    return self.value() >= 1
  }
}
