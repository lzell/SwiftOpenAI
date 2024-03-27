//
//  File.swift
//  
//
//  Created by Lou Zell on 3/26/24.
//

import Foundation
import DeviceCheck
import UIKit
import OSLog

private let aiproxyPartialKey = "v1|073a78af|9|9x8SNKe00tveUCeg"
#if DEBUG && targetEnvironment(simulator)
private let aiproxyDeviceCheckBypass = "ebf426a1-958b-4c1f-a911-115187116b0b"
#endif
private let aiproxyLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
                                   category: "AIProxy")


// MARK: Endpoint+AIproxy
extension Endpoint {

    func request(
       method: HTTPMethod,
       params: Encodable? = nil,
       queryItems: [URLQueryItem] = []
    )
       async throws -> URLRequest
    {
       var request = URLRequest(url: urlComponents(queryItems: queryItems).url!)
       request.addValue("application/json", forHTTPHeaderField: "Content-Type")
       // request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
        let deviceCheckToken = await getDeviceCheckToken()
        let vendorID = getVendorID()

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
