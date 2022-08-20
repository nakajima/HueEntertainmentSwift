//
//  JSONTypes.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation

struct HueBridgeResponse: Codable {
  var id: String?
  var internalipaddress: String
  var port: Int
  var macaddress: String?
  var name: String?
}

struct HueEntertainmentAreaResponse: Codable {
  let errors: [String]
  let data: [HueEntertainmentArea]
}

// MARK: - Welcome

struct HueEntertainmentArea: Codable {
  let id: String
  let id_v1: String?
  let type: String?
  let metadata: HueEntertainmentAreaMetadata?
  let configurationType: String?
  let channels: [HueEntertainmentAreaChannel]?
  let status: String?
}

// MARK: - Channel

struct HueEntertainmentAreaChannel: Codable {
  let channel_id: Int
  let position: HueEntertainmentAreaPosition?
}

// MARK: - Position

struct HueEntertainmentAreaPosition: Codable {
  let x: Double?
  let y: Double?
  let z: Double?
}

// MARK: - Metadata

struct HueEntertainmentAreaMetadata: Codable {
  let name: String?
}

struct HueBridgeCheck: Codable {
  let name: String
  let swversion: String
  let apiversion: String
  let mac: String
  let bridgeid: String
  let factorynew: Bool
  let replacesbridgeid: String?
  let modelid: String
}

struct BridgeKeyRequest: Codable {
  let devicetype: String
  let generateclientkey: Bool
}

struct BridgeKey: Codable {
  let username: String
  let clientkey: String
}

struct BridgeError: Codable {
  let type: Int?
  let address: String?
  let description: String?
}

struct BridgeKeyResponse: Codable {
  let success: BridgeKey?
  let error: BridgeError?
}

struct BridgeAction: Codable {
  let action: String
}
