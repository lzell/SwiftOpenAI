//
//  Endpoint.swift
//
//
//  Created by James Rochabrun on 10/11/23.
//

import Foundation

// Needed for AIProxy only. Move elsewhere
import DeviceCheck
import UIKit
import OSLog


// MARK: HTTPMethod

private let aiproxyPartialKey = "v1|073a78af|9|9x8SNKe00tveUCeg"
#if DEBUG && targetEnvironment(simulator)
private let aiproxyDeviceCheckBypass = "ebf426a1-958b-4c1f-a911-115187116b0b"
#endif
private let aiproxyLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
                                   category: "AIProxy")


enum HTTPMethod: String {
   case post = "POST"
   case get = "GET"
   case delete = "DELETE"
}

// MARK: Endpoint

protocol Endpoint {
   
   var base: String { get }
   var path: String { get }
}

// MARK: Endpoint+Requests

extension Endpoint {

   private func urlComponents(
      queryItems: [URLQueryItem])
      -> URLComponents
   {
      var components = URLComponents(string: base)!
      components.path = path
      if !queryItems.isEmpty {
         components.queryItems = queryItems
      }
      return components
   }
   
   func request(
      apiKey: Authorization,
      organizationID: String?,
      method: HTTPMethod,
      params: Encodable? = nil,
      queryItems: [URLQueryItem] = [],
      betaHeaderField: String? = nil)
      async throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      // request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
       let deviceCheckToken = await getDeviceCheckToken()
       let vendorID = getVendorID()


      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      if let betaHeaderField {
         request.addValue(betaHeaderField, forHTTPHeaderField: "OpenAI-Beta")
      }
      request.httpMethod = method.rawValue
      if let params {
         request.httpBody = try JSONEncoder().encode(params)
      }
       request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")

       if let vendorID = vendorID {
           request.addValue(vendorID, forHTTPHeaderField: "aiproxy-vendor-id")
       }

       if let deviceCheckToken = deviceCheckToken {
           request.addValue(deviceCheckToken, forHTTPHeaderField: "aiproxy-devicecheck")
       }
   #if DEBUG && targetEnvironment(simulator)
       request.addValue(aiproxyDeviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
   #endif

      return request
   }
   
   func multiPartRequest(
      apiKey: Authorization,
      organizationID: String?,
      method: HTTPMethod,
      params: MultipartFormDataParameters,
      queryItems: [URLQueryItem] = [])
      async throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.httpMethod = method.rawValue
      let boundary = UUID().uuidString
      // request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
       let deviceCheckToken = await getDeviceCheckToken()
       let vendorID = getVendorID()

      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
       request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")

       if let vendorID = vendorID {
           request.addValue(vendorID, forHTTPHeaderField: "aiproxy-vendor-id")
       }

       if let deviceCheckToken = deviceCheckToken {
           request.addValue(deviceCheckToken, forHTTPHeaderField: "aiproxy-devicecheck")
       }
   #if DEBUG && targetEnvironment(simulator)
       request.addValue(aiproxyDeviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
   #endif

      request.httpBody = params.encode(boundary: boundary)
      return request
   }
}


/// Gets a device check token for use in your calls to aiproxy.
/// The device token may be nil when targeting the iOS simulator.
/// See the usage instructions at the top of this file, and ensure that you are conditionally compiling the `deviceCheckBypass` token for iOS simulation only.
/// Do not let the `deviceCheckBypass` token slip into your production codebase, or an attacker can easily use it themselves.
private func getDeviceCheckToken() async -> String? {
    guard DCDevice.current.isSupported else {
        aiproxyLogger.error("DeviceCheck is not available on this device. Are you on the simulator?")
        return nil
    }

    do {
        let data = try await DCDevice.current.generateToken()
        return data.base64EncodedString()
    } catch {
        aiproxyLogger.error("Could not create DeviceCheck token. Are you using an explicit bundle identifier?")
        return nil
    }
}

/// Get a unique ID for this user (scoped to the current vendor, and not personally identifiable):
private func getVendorID() -> String? {
    return UIDevice.current.identifierForVendor?.uuidString
}
