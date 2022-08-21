//
//  Session.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import Network

@available(iOS 14.0, *)
public class HueSession: NSObject, URLSessionDelegate {
  public var ip: String?
  public var username: String?
  public var clientKey: String?
  public var appID: String?
  public var connection: NWConnection?
  public var area: HueEntertainmentArea?

  var urlsession: URLSession!
  var queue = DispatchQueue(label: "HueSessionQueue")
  var updates: [AreaUpdate] = []
  var timer: Timer?

  override public init() {
    super.init()
    self.urlsession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    self.initTimer()
  }

  deinit {
    self.cancelTimer()
  }

  func initTimer() {
    self.cancelTimer()
    DispatchQueue.main.async {
      let timer = Timer(timeInterval: 1.0 / 50.0, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
      RunLoop.current.add(timer, forMode: .common)
      self.timer = timer
    }
  }

  func cancelTimer() {
    self.timer?.invalidate()
  }

  public var isConnected: Bool {
    self.connection != nil
  }

  public func areas() async throws -> [HueEntertainmentArea] {
    guard let areaResponse: HueEntertainmentAreaResponse = try await get("clip/v2/resource/entertainment_configuration") else {
      throw HueError.requestError("Could not load areas")
    }

    if !areaResponse.errors.isEmpty {
      throw HueError.requestError("Error loading areas: \(areaResponse.errors.debugDescription)")
    }

    if areaResponse.data.isEmpty {
      throw HueError.requestError("No areas found")
    }

    return areaResponse.data
  }

  public func start(area: HueEntertainmentArea) async throws {
    let _: BridgeKeyResponse? = try await put("clip/v2/resource/entertainment_configuration/\(area.id)", data: BridgeAction(action: "start"))
    self.area = area
  }

  public func stop() async throws {
    guard let area else {
      throw HueError.connectionError("Cannot stop (no area set)")
    }

    self.connection?.cancel()
    let _: BridgeKeyResponse? = try await put("clip/v2/resource/entertainment_configuration/\(area.id)", data: BridgeAction(action: "stop"))
  }
}
