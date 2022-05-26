// Actions

import Foundation

enum Auth {
    case basic(String, String)
    
    var value: String {
        switch self {
        case let .basic(username, password):
            let base64 = Data("\(username):\(password)".utf8).base64EncodedString()
            return "Basic \(base64)"
        }
    }
}

func httpRequest(url: String, method: String = "GET", headers: [String: String] = [:], auth: Auth? = nil) throws -> (Data?, URLResponse) {
    var data: Data? = nil
    var response: URLResponse? = nil
    var error: Error? = nil
    
    var allHeaders = headers
    if let auth = auth {
        allHeaders["Authorization"] = auth.value
    }
    
    var request = URLRequest(url: URL(string: url)!);
    request.httpMethod = method
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

func githubSearch(_ query: String) throws -> [ContentItem] {
    let url = "https://api.github.com/search/issues?q=\(query)"
    let (data, _) = try httpRequest(url: url, auth: .basic("joshdholtz", "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"))
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    let decodedResponse = try decoder.decode(GitHub.SearchResponse.self, from: data!)
    return decodedResponse.items
}

protocol ContentItem: Codable {
    
}

extension ContentItem {
    func toString() -> String? {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        if let data = data, let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
}

// Github

struct GitHub {
    struct SearchResponse: Codable {
        let totalCount: Int
        let incompleteResults: Bool
        let items: [Item]
        
        struct Item: Codable, Identifiable {
            let htmlUrl: String
            let id: Int
            let number: Int
            let title: String
            let user: User
            let createdAt: Date
        }
    }
    
    struct User: Codable {
        let login: String
    }
}

extension GitHub.SearchResponse.Item: ContentItem {
    
}

// DSL

@resultBuilder
enum PaneArrayBuilder {
    static func buildEither(first component: [Pane]) -> [Pane] {
        return component
    }
    
    static func buildEither(second component: [Pane]) -> [Pane] {
        return component
    }
    
    static func buildBlock(_ components: [Pane]...) -> [Pane] {
        return components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [Pane]?) -> [Pane] {
        return component ?? []
    }
    
    static func buildExpression(_ expression: Pane) -> [Pane] {
        return [expression]
    }
    
    static func buildExpression(_ expression: Void) -> [Pane] {
        return []
    }
}

typealias PaneContent = () throws -> ([ContentItem])

struct Pane {
    var name: String
    var content: PaneContent
}

extension Pane {
    
}

struct Dashboard {
    var name: String
    @PaneArrayBuilder var panes: () -> [Pane]
}

let dashboard = 
// ^ prepend to file

Dashboard(name: "fastlane") {
    Pane(name: "Open PRs") {
        try githubSearch("repo:fastlane/fastlane+is:pr+is:open")
    }
    Pane(name: "High Activity Issues") {
        []
    }
    Pane(name: "My PRs") {
        []
    }
}

// runner

let contents = (try? dashboard.panes().compactMap({ pane in
    try pane.content()
}))?.flatMap({$0}).compactMap({$0.toString()}) ?? []

for content in contents {
    print(content)
}
