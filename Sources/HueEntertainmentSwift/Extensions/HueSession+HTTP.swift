//
//  Session+HTTP.swift
//
//
//  Created by Pat Nakajima on 8/20/22.
//

import Foundation

@available(iOS 14.0, *)
extension HueSession {
	struct DummyCodable: Codable {}

	public func put<InputType: Codable, ReturnType: Codable>(_ path: String, data: InputType) async throws -> ReturnType? {
		return try await makeRequest(method: "PUT", path: path, data: data)
	}

	public func get<ReturnType: Codable>(_ path: String) async throws -> ReturnType? {
		return try await makeRequest(method: "GET", path: path, data: DummyCodable?.none)
	}

	public func post<InputType: Codable, ReturnType: Codable>(_ path: String, data: InputType) async throws -> ReturnType? {
		return try await makeRequest(method: "POST", path: path, data: data)
	}

	public func urlSession(_: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if challenge.protectionSpace.serverTrust == nil {
			completionHandler(.useCredential, nil)
		} else {
			let trust: SecTrust = challenge.protectionSpace.serverTrust!
			let credential = URLCredential(trust: trust)
			completionHandler(.useCredential, credential)
		}
	}

	func makeRawRequest(method: String, path: String, configuration: ((inout URLRequest) async throws -> Void)? = nil) async throws -> (Data, URLResponse) {
		guard let ip = ip else {
			throw HueError.requestError("NO IP")
		}

		guard let url = URL(string: "https://\(ip)/\(path)") else {
			throw HueError.requestError("NO URL??? https://\(ip)/\(path)")
		}

		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		if let configuration = configuration {
			try await configuration(&request)
		}

		return try await urlsession.data(for: request)
	}

	private func makeRequest<InputType: Codable, ReturnType: Codable>(method: String, path: String, data: InputType? = nil) async throws -> ReturnType? {
		let (responseData, _) = try await makeRawRequest(method: method, path: path) { request in
			if let data = data {
				let body = try JSONEncoder().encode(data)
				request.httpBody = body
			}

			if let username = self.username {
				request.setValue(username, forHTTPHeaderField: "hue-application-key")
			}
		}

		let decoded = try JSONDecoder().decode(ReturnType.self, from: responseData)
		return decoded
	}
}
