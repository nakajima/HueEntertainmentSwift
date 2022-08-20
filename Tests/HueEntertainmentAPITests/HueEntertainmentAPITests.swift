@testable import HueEntertainmentSwift
import XCTest

@available(iOS 13.0, *)
final class HueEntertainmentAPITests: XCTestCase {
  func testExample() async throws {
    let session = HueSession()
    session.ip = "YOUR IP"
    session.username = "A USERNAME FROM YOUR BRIDGE"
    session.clientKey = "A CLIENT KEY FROM YOUR BRIDGE"
    session.appID = "AN APP ID FROM YOUR BRIDGE"

    let areas = try await session.areas()
    let area = areas.first!

    try await session.start(areaID: area.id)
    try await session.connect()

    guard let connection = session.connection else {
      XCTFail("NO connection")
      return
    }

    let red = Message(area: area, color: "FF0000").data
    let green = Message(area: area, color: "00FF00").data
    let blue = Message(area: area, color: "0000FF").data

    for _ in 0 ..< 10 {
      connection.send(content: red, completion: .idempotent)
      try await Task.sleep(nanoseconds: 100_000_000)
      connection.send(content: green, completion: .idempotent)
      try await Task.sleep(nanoseconds: 100_000_000)
      connection.send(content: blue, completion: .idempotent)
      try await Task.sleep(nanoseconds: 100_000_000)
    }

    try await session.stop()
  }
}
