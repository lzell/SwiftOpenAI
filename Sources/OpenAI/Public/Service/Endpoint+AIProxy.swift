//
//  Endpoint.swift
//
//
//  Created by James Rochabrun on 10/11/23.
//

import Foundation

// MARK: Endpoint+AIProxy

extension Endpoint {

    private func urlComponents(
       queryItems: [URLQueryItem])
       -> URLComponents
    {
       var components = URLComponents(string: "https://api.aiproxy.pro")!
       components.path = path
       if !queryItems.isEmpty {
          components.queryItems = queryItems
       }
       return components
    }

   func request(
      aiproxyPartialKey: String,
      organizationID: String?,
      method: HTTPMethod,
      params: Encodable? = nil,
      queryItems: [URLQueryItem] = [],
      betaHeaderField: String? = nil,
      deviceCheckBypass: String? = nil)
      throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")
      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      if let betaHeaderField {
         request.addValue(betaHeaderField, forHTTPHeaderField: "OpenAI-Beta")
      }
#if DEBUG && targetEnvironment(simulator)
      if let deviceCheckBypass = deviceCheckBypass {
         request.addValue(deviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
      }
#endif
      request.httpMethod = method.rawValue
      if let params {
         request.httpBody = try JSONEncoder().encode(params)
      }
      return request
   }

   func multiPartRequest(
      aiproxyPartialKey: String,
      organizationID: String?,
      method: HTTPMethod,
      params: MultipartFormDataParameters,
      queryItems: [URLQueryItem] = [],
      deviceCheckBypass: String? = nil)
      throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.httpMethod = method.rawValue
      let boundary = UUID().uuidString
      request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")
      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
#if DEBUG && targetEnvironment(simulator)
      if let deviceCheckBypass = deviceCheckBypass {
         request.addValue(deviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
      }
#endif
      request.httpBody = params.encode(boundary: boundary)
      return request
   }
}
