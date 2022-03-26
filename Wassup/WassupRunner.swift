//
//  WassupRunner.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

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
    
    var request = URLRequest(url: URL(string: url)!)
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

protocol ContentItem: Codable {
    var itemTitle: String { get }
    var itemSubtitle: String? { get }
    var actions: [Output.Action] { get }
}

struct Output: Codable {
    let panes: [Pane]
    
    struct Pane: Codable {
        enum CountAlert: String, Codable {
            case none, low, medium, high
        }
        
        let name: String
        let alert: CountAlert
        let items: [Item]
    }
    
    struct Item: Codable {
        let title: String
        let subtitle: String?
        
        let meta: String?
        
        let actions: [Output.Action]
    }
    
    struct Action: Codable {
        let name: String
        let value: ActionValue
    }
    
    func toString() -> String? {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        if let data = data, let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
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

@resultBuilder
enum ContentArrayBuilder {
    static func buildBlock(_ components: [ContentItem]...) -> [ContentItem] {
        return components.flatMap { $0 }
    }
    
    static func buildExpression(_ expression: GitHubSearch) -> [ContentItem] {
        return expression.toItems()
    }
    
    static func buildExpression(_ expression: Item) -> [ContentItem] {
        return [expression]
    }
}

typealias PaneContent = () throws -> ([ContentItem])

struct Item: ContentItem {
    let title: String
    let subtitle: String?
    let actions: [Output.Action]
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actions = []
    }
    
    // This feels gross
    var itemTitle: String {
        return title
    }
    var itemSubtitle: String? {
        return subtitle
    }
}

protocol ContentBuilder {
    
}

extension ContentItem {
    func action(action: (Self) -> (ActionValue)) -> Self {
        return self
    }
}

typealias GitHubSearchAction = (GitHub.SearchResponse.Item) -> (ActionValue)
extension GitHubSearch {
    func action(_ name: String, action: @escaping GitHubSearchAction) -> Self {
        var actions = self.actions
        actions[name] = action
        
        return GitHubSearch(self.q, self.qualifiers, actions)
    }
}

enum ActionValue: Codable {
    case url(String), shell(String)
}

struct ReturnContentItem<T: Codable>: ContentItem {
    let itemTitle: String
    let itemSubtitle: String?

    let contentItem: T
    
    let actions: [Output.Action]
}

struct GitHubSearch: ContentBuilder {
    enum Qualifer {
        var dateFormatter: DateFormatter {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter
        }
        
        case createdLessThan(Int), createdMoreThan(Int)
        
        var value: String {
            switch self {
            case let .createdLessThan(days):
                let date = Calendar.current.date(byAdding: .day, value: -days, to: Date())
                return "created:>\(dateFormatter.string(from: date!))"
            case let .createdMoreThan(days):
                let date = Calendar.current.date(byAdding: .day, value: -days, to: Date())
                return "created:<\(dateFormatter.string(from: date!))"
            }
        }
    }
    
    var q: String
    var qualifiers: [Qualifer]
    
    var actions: [String: GitHubSearchAction]
    
    init(_ q: String, _ qualifiers: [Qualifer] = [], _ actions: [String: GitHubSearchAction]? = nil) {
        self.q = q
        self.qualifiers = qualifiers
        self.actions = actions ?? [
            "Open": { item in
                return .url(item.htmlUrl)
            }
        ]
    }
        
    func toItems() -> [ReturnContentItem<GitHub.SearchResponse.Item>] {
        do {
            let newQ = ([q] + qualifiers.map({$0.value})).joined(separator: " ")
            
            let encodedQ = newQ.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? newQ
            
            let githubUsername = ProcessInfo.processInfo.environment["GITHUB_USERNAME"]!
            let githubApiKey = ProcessInfo.processInfo.environment["GITHUB_API_KEY"]!
            
            let url = "https://api.github.com/search/issues?q=\(encodedQ)"
//            let (data, _) = try httpRequest(url: url, auth: .basic("joshdholtz", "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"))
            let (data, _) = try httpRequest(url: url, auth: .basic(githubUsername, githubApiKey))
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let decodedResponse = try decoder.decode(GitHub.SearchResponse.self, from: data!)
            return decodedResponse.items.map { item in
                return ReturnContentItem(
                    itemTitle: item.itemTitle,
                    itemSubtitle: item.itemSubtitle,
                    contentItem: item,
                    actions: actions.map({ (key: String, value: GitHubSearchAction) in
                        let theValue = value(item)
                        return Output.Action(name: key, value: theValue)
                    })
                )
            }
        } catch {
            // TODO: Handle this error
            print("Error in GitHub Search: \(error)")
        }
        
        return []
    }
}

struct Pane {
    var name: String
    var alert: Output.Pane.CountAlert
    @ContentArrayBuilder var contents: () -> [ContentItem]
    
    init(_ name: String, alert:  Output.Pane.CountAlert = .none, @ContentArrayBuilder contents: @escaping () -> [ContentItem]) {
        self.name = name
        self.alert = alert
        
        self.contents = contents
    }
    
    
}

struct Dashboard {
    var name: String
    @PaneArrayBuilder var panes: () -> [Pane]
    
    init(_ name: String, @PaneArrayBuilder panes: @escaping () -> [Pane]) {
        self.name = name
        self.panes = panes
    }
}

extension Dashboard {
    func toString() throws -> String? {
        let panes: [Output.Pane] = self.panes().map { pane -> Output.Pane in
            let outputItems: [Output.Item] = pane.contents().map { contentItem -> Output.Item in
                let title = contentItem.itemTitle
                let subtitle = contentItem.itemSubtitle
                let meta = contentItem.toString()
                let actions = contentItem.actions
                
                return Output.Item(title: title, subtitle: subtitle, meta: meta, actions: actions)
            }
            
            let outputPane = Output.Pane(name: pane.name,
                                         alert: pane.alert,
                                         items: outputItems)
            
            return outputPane
        }
        
        let output = Output(panes: panes)
        return output.toString()
    }
}
