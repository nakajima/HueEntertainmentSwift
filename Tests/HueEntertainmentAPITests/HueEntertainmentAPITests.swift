@testable import HueEntertainmentSwift
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class HueEntertainmentAPITests: XCTestCase {
  func testExample() async throws {
    let session = HueSession()

    try await session.findIP()
    try await session.login(device: "swift#test")

    print("username:\(session.username) clientKey:\(session.clientKey) appID:\(session.appID)")

    let areas = try await session.areas()
    let area = areas.first!
//
    try await session.start(area: area)
    try session.connect()

//
    guard let connection = session.connection else {
      XCTFail("NO connection")
      return
    }

    for _ in 0 ..< 10 {
      session.on(colors: [Color.pink, Color.indigo, Color.cyan])
      try await Task.sleep(nanoseconds: 300_000_000)
      session.off()
      try await Task.sleep(nanoseconds: 100_000_000)
    }

    try await session.stop()
  }
}
