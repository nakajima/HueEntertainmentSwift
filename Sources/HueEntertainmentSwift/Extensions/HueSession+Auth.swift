//
//  File.swift
//
//
//  Created by Pat Nakajima on 8/21/22.
//

import Foundation
import Network

public enum HueError: Error {
	case requestError(String)
	case connectionError(String)
	case bridgeError(String)
	case linkButtonNotPressedError
}

@available(iOS 14.0, *)
public extension HueSession {
	/**
	 Establishes a ``connection`` to the bridge and allows you to stream to it.
	 */
	func connect() throws {
		guard var ip = ip, var address = IPv4Address(ip), var clientKey = self.clientKey, var appID = self.appID, var username = self.username else {
			throw HueError.connectionError("Could not connect")
		}

		let options = NWProtocolTLS.Options()

		let clientKeyBytes = clientKey.hexToBytes
		let psk = clientKeyBytes.withUnsafeBytes { bytes in DispatchData(bytes: bytes) } as __DispatchData
		let pskIdentity = appID.data(using: .utf8)!.withUnsafeBytes { DispatchData(bytes: $0) } as __DispatchData

		sec_protocol_options_append_tls_ciphersuite(options.securityProtocolOptions, tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
		sec_protocol_options_add_pre_shared_key(options.securityProtocolOptions, psk, pskIdentity)
		sec_protocol_options_set_min_tls_protocol_version(options.securityProtocolOptions, .DTLSv12)
		sec_protocol_options_set_max_tls_protocol_version(options.securityProtocolOptions, .DTLSv12)
		sec_protocol_options_set_verify_block(options.securityProtocolOptions, { (_: sec_protocol_metadata_t, _: sec_trust_t, complete: @escaping sec_protocol_verify_complete_t) in
			complete(true)
		}, queue)

		let connection = NWConnection(host: NWEndpoint.Host.ipv4(address), port: 2100, using: .init(dtls: options))

		connection.stateUpdateHandler = { [weak self] state in
			guard let self = self else {
				return
			}

			switch state {
			case .ready:
				self.connection = connection
			case .cancelled:
				self.connection = nil
			case let .failed(err): connection.cancel()
			@unknown default:
				print("??")
			}
		}

		connection.start(queue: queue)
	}

	/**
	 Finds the IP of your Hue bridge and sets ``ip`` on this session. It's best to save this value an set it on the session instead
	 of calling this repeatedly, as you can run into rate-limiting issues.
	 */
	func findIP() async throws {
		let url = URL(string: "https://discovery.meethue.com")!
		let (data, _) = try await urlsession.data(from: url)
		let bridgeResponse = try JSONDecoder().decode([HueBridgeResponse].self, from: data)

		if let response = bridgeResponse.first {
			ip = response.internalipaddress
		} else {
			throw HueError.bridgeError("No bridge found")
		}
	}

	/**
	 Helper to see if bridge is accessible.
	 */
	func check() async throws -> Bool {
		guard let ip = ip else {
			return false
		}

		let url = URL(string: "https://\(ip)/api/0/config")!
		do {
			let (data, _) = try await urlsession.data(from: url)
			_ = try JSONDecoder().decode(HueBridgeCheck.self, from: data)
		} catch {
			return false
		}

		return true
	}

	/**
	 Sets ``username``, ``clientKey``, and ``appID`` properties for this session. It's best to save these values and set them on the session instead
	 of calling ``login(device:)`` each time.

	 > Important: This method requires the user to press the link button on their Hue bridge. If the link button has not been pressed, a ``linkButtonNotPressedError`` error will be thrown.
	 */
	func login(device: String) async throws {
		let bridgeResponse: [BridgeKeyResponse]? = try await post("api", data: BridgeKeyRequest(devicetype: device, generateclientkey: true))

		guard let creds = bridgeResponse?.first else {
			throw HueError.requestError("NO CREDS")
		}

		if let error = creds.error {
			if error.description == "link button not pressed" {
				throw HueError.linkButtonNotPressedError
			} else {
				throw HueError.bridgeError(error.description ?? "bridge error")
			}
		}

		self.username = creds.success?.username
		clientKey = creds.success?.clientkey

		guard let username = self.username else {
			throw HueError.requestError("NO USERNAME")
		}

		let (_, response) = try await makeRawRequest(method: "GET", path: "auth/v1") { request in
			request.setValue(username, forHTTPHeaderField: "hue-application-key")
		}

		let res = response as! HTTPURLResponse
		appID = res.value(forHTTPHeaderField: "hue-application-id")
	}
}
