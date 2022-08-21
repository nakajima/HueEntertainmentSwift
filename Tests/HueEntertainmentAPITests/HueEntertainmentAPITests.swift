@testable import HueEntertainmentSwift
import SwiftUI
import XCTest

@available(iOS 14.0, *)
final class HueEntertainmentAPITests: XCTestCase {
  func testExample() async throws {
    let session = HueSession()
    HueSession.settings.forceFullBrightness = true

    // You should save these credentials and set them manually on the HueSession so you don't
    // need to always look up the bridge IP and press the button.
    //
    // It'll look like this:
    //
    // session.ip = "IP OF YOUR BRIDGE"
    // session.username = "YOUR USERNAME"
    // session.clientKey = "CLIENT KEY"
    // session.appID = "APP ID"
    //
    // Once you've saved them, you can comment out the `findIP` and `login` calls.
    try await session.findIP()

    do {
      try await session.login(device: "swift#test")
    } catch HueError.linkButtonNotPressedError {
      XCTFail("Press link button then re-run")
      return
    } catch {
      XCTFail("Failed with \(error)")
      return
    }

    print("username:\(session.username) clientKey:\(session.clientKey) appID:\(session.appID)")

    // This example assumes you have an entertainment area set up already in the Hue app
    let areas = try await session.areas()
    guard let area = areas.first else {
      XCTFail("No area found. Set one up in the Hue app.")
      return
    }

    try await session.start(area: area)
    try session.connect()

    for _ in 0 ..< 3 {
      session.on(colors: [Color.red, Color.green, Color.blue, Color.yellow], ramp: 2)
      try await Task.sleep(nanoseconds: 3_000_000_000)
      session.off()
      try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    try await session.stop()
  }

  func testAnimationMath() {
    let time = Date()

    let animation = Animation(startAt: time, duration: 1, curve: .linear)

    XCTAssertEqual(0, animation.value(at: time))

    let then = time.addingTimeInterval(0.5)
    XCTAssertEqual(0.5, animation.value(at: then))

    let done = time.addingTimeInterval(1)
    XCTAssertEqual(1, animation.value(at: done))
  }
}
