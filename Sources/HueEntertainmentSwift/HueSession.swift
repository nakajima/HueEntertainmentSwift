//
//  Session.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import Network

/**
 Manages connection to Hue bridge and provides functions for turning lights on/off.
 */
@available(iOS 14.0, *)
public class HueSession: NSObject, URLSessionDelegate {
	/**
	 The local network IP of your bridge. Can be set by calling ``findIP()``.

	 > Tip: It's best to save this value instead of needing to look it up each time.
	 */
	public var ip: String?

	/**
	 The username provided by the bridge after auth. Can be set by calling ``login(device:)`` It's best to save this value instead of needing to login each time.

	 > Tip: It's best to save this value instead of needing to look it up each time.
	 */
	public var username: String?

	/**
	 The clientKey provided by the bridge after auth. Can be set by calling ``login(device:)`` It's best to save this value instead of needing to login each time.

	  > Tip: It's best to save this value instead of needing to look it up each time.
	 */
	public var clientKey: String?

	/**
	 The `hue-application-id` provided by the bridge after auth. Can be set by calling ``login(device:)``

	 > Tip: It's best to save this value instead of needing to login each time.
	 */
	public var appID: String?

	/// The connection used to send UDP messages to the bridge.
	public var connection: NWConnection?

	/// The entertainment area (configured in the Hue app) to be controlled
	public var area: HueEntertainmentArea?

	var urlsession: URLSession!
	var queue = DispatchQueue(label: "HueSessionQueue")
	var updates: [AreaUpdate] = []
	var timer: Timer?

	override public init() {
		super.init()
		self.urlsession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
		initTimer()
	}

	deinit {
		self.cancelTimer()
	}

	func initTimer() {
		cancelTimer()
		DispatchQueue.main.async {
			let timer = Timer(timeInterval: 1.0 / 50.0, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
			RunLoop.current.add(timer, forMode: .common)
			self.timer = timer
		}
	}

	func cancelTimer() {
		timer?.invalidate()
	}

	/// Has this session authed and connected with the bridge
	public var isConnected: Bool {
		connection != nil
	}

	/// Returns the available entertainment areas configured in the Hue app. You'll use one of these set ``area`` on the session.
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

	/// Starts streaming to the bridge for the given entertainment area. Required to be called before sending messages.
	public func start(area: HueEntertainmentArea) async throws {
		let _: BridgeKeyResponse? = try await put("clip/v2/resource/entertainment_configuration/\(area.id)", data: BridgeAction(action: "start"))
		self.area = area
	}

	/// Stops the streaming session to the bridge. Call this when you're done sending messages, otherwise no other integration will be able to stream to your entertainment area.
	public func stop() async throws {
		guard let area = area else {
			throw HueError.connectionError("Cannot stop (no area set)")
		}

		connection?.cancel()
		let _: BridgeKeyResponse? = try await put("clip/v2/resource/entertainment_configuration/\(area.id)", data: BridgeAction(action: "stop"))
	}
}
