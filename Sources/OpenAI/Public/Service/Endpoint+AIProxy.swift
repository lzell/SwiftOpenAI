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

   func requestX(
      apiKey: Authorization,
      organizationID: String?,
      method: HTTPMethod,
      params: Encodable? = nil,
      queryItems: [URLQueryItem] = [],
      betaHeaderField: String? = nil)
      throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
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
      return request
   }

   func multiPartRequestX(
      apiKey: Authorization,
      organizationID: String?,
      method: HTTPMethod,
      params: MultipartFormDataParameters,
      queryItems: [URLQueryItem] = [])
      throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
      request.httpMethod = method.rawValue
      let boundary = UUID().uuidString
      request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.encode(boundary: boundary)
      return request
   }
}

//private extension OpenAIAPI {
//    var base: String {
//        "https://api.aiproxy.pro"
//    }
//}
