//
//  Helpers.swift
//  Wassup
//
//  Created by Josh Holtz on 4/1/22.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

enum Auth {
    case basic(String, String)
    case custom(String)
    
    var value: String {
        switch self {
        case let .basic(username, password):
            let base64 = Data("\(username):\(password)".utf8).base64EncodedString()
            return "Basic \(base64)"
        case let .custom(value):
            return value
        }
    }
}

func httpRequest(url: String, method: String = "GET", headers: [String: String] = [:], body: Data? = nil, auth: Auth? = nil) throws -> (Data?, URLResponse) {
    var data: Data? = nil
    var response: URLResponse? = nil
    var error: Error? = nil
    
    var allHeaders = headers
    if let auth = auth {
        allHeaders["Authorization"] = auth.value
    }
    
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = method
    request.allHTTPHeaderFields = allHeaders
    request.httpBody = body
    let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    let task = URLSession.shared.dataTask(with: request) { (theData, theResponse, theError) in
        data = theData
        response = theResponse
        error = theError
        semaphore.signal()
    }
    task.resume()
    semaphore.wait()
    
    if let error = error {
        throw error
    }
    
    return (data, response!)
}
