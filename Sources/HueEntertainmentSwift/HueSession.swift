//
//  Session.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation
import Network

enum HueError: Error {
  case requestError(String)
  case connectionError(String)
}

@available(iOS 13.0, *)
public class HueSession: NSObject, URLSessionDelegate {
  var ip: String?
  var username: String?
  var clientKey: String?
  var appID: String?
  var urlsession: URLSession!
  var connection: NWConnection?
  var queue = DispatchQueue(label: "HueSessionQueue")
  var area: HueEntertainmentArea?

  override public init() {
    super.init()
    self.urlsession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
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

    let _: BridgeKeyResponse? = try await put("clip/v2/resource/entertainment_configuration/\(area.id)", data: BridgeAction(action: "stop"))
  }

  public func connect() throws {
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
    }, self.queue)

    let connection = NWConnection(host: NWEndpoint.Host.ipv4(address), port: 2100, using: .init(dtls: options))

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        print("READY")
      case .cancelled: print("CANCELLED")
      case let .failed(err): print("FAILED \(err.debugDescription)")
      case let .waiting(err): print("WAITING \(err.debugDescription)")
      case .setup: print("SETUP")
      case .preparing:
        print("PREPARING")
      @unknown default:
        print("??")
      }
    }

    connection.start(queue: self.queue)
    self.connection = connection
  }

  public func findIP() async throws {
    let url = URL(string: "https://discovery.meethue.com")!
    let (data, _) = try await urlsession.data(from: url)
    let bridgeResponse = try JSONDecoder().decode([HueBridgeResponse].self, from: data)

    if let response = bridgeResponse.first {
      print(String(describing: bridgeResponse))
      self.ip = response.internalipaddress
    } else {
      print("NO BRIDGE FOUND")
    }
  }

  public func check() async throws -> Bool {
    guard let ip = ip else {
      return false
    }

    let url = URL(string: "https://\(ip)/api/0/config")!
    do {
      let (data, _) = try await urlsession.data(from: url)
      let bridgeResponse = try JSONDecoder().decode(HueBridgeCheck.self, from: data)
      print("CHECK \(bridgeResponse)")
    } catch {
      print("ERROR LOADING \(error)")
      return false
    }

    return true
  }

  public func login(device: String) async throws {
    do {
      let bridgeResponse: [BridgeKeyResponse]? = try await post("api", data: BridgeKeyRequest(devicetype: device, generateclientkey: true))

      guard let creds = bridgeResponse?.first else {
        throw HueError.requestError("NO CREDS")
      }

      self.username = creds.success?.username
      self.clientKey = creds.success?.clientkey

      guard let username = self.username else {
        throw HueError.requestError("NO USERNAME")
      }

      let (_, response) = try await makeRawRequest(method: "GET", path: "auth/v1") { request in
        request.setValue(username, forHTTPHeaderField: "hue-application-key")
      }

      let res = response as! HTTPURLResponse
      self.appID = res.value(forHTTPHeaderField: "hue-application-id")
    } catch {
      print("ERROR POST \(error)")
    }
  }
}
