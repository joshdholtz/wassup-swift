//
//  GitHub.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

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
    var showExtras: Bool
    var qualifiers: [Qualifer]
    
    var actions: [(String?, String?, GitHubSearchAction)]? = nil
    
    var defaultActions: [(String?, String?, GitHubSearchAction)] =  [(nil, "square.and.arrow.up", { .url($0.url) })]
    
    init(_ q: String, _ qualifiers: [Qualifer] = [], showExtras: Bool = false, _ actions: [(String?, String?, GitHubSearchAction)]? = nil) {
        self.q = q
        self.qualifiers = qualifiers
        self.showExtras = showExtras
        self.actions = actions ?? defaultActions
    }
    
    func toItems() -> [ContentItem] {
        do {
            let newQ = ([q] + qualifiers.map({$0.value})).joined(separator: " ")
            
            let githubUsername = ProcessInfo.processInfo.environment["GITHUB_USERNAME"]!.trimmingCharacters(in: .whitespacesAndNewlines)
            let githubApiKey = ProcessInfo.processInfo.environment["GITHUB_API_KEY"]!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let url = "https://api.github.com/graphql"
            let query = GitHubSearchData.makeSearchQuery(q: newQ)
            
            let body = try! JSONEncoder().encode([
                "query": query
            ])
            
//            print("JSON BODY")
//            print(String(data: body, encoding: .utf8))
            
            let (data, _) = try httpRequest(url: url, method: "POST", body: body, auth: .basic(githubUsername, githubApiKey))
            
//            print("DATA")
//            print(String(data: data!, encoding: .utf8))
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let decodedResponse = try decoder.decode(GitHubSearchData.Response.self, from: data!)
            return decodedResponse.data.search.nodes.map { item in
                let contentItem = item.asItem
                
                let actions = self.actions ?? []
                
                return ContentItem(
                    title: contentItem.title,
                    subtitle: contentItem.subtitle,
                    extras: showExtras ? contentItem.extras : [],
//                    contentItem: item,
                    actions: actions.map({ (key: String?, image: String?, value: GitHubSearchAction) in
                        let theValue = value(item)
                        return Output.Action(name: key, image: image, value: theValue)
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

typealias GitHubSearchAction = (GitHubSearchData.Response.Search.Node) -> (ActionValue)
extension GitHubSearch {
    func action(label name: String? = nil, image: String? = nil, clearPrevious: Bool = false, action: @escaping GitHubSearchAction) -> Self {
        let actions = (clearPrevious ? [] : self.actions ?? []) + [(name, image, action)]
        
        return GitHubSearch(self.q, self.qualifiers, actions)
    }
}

extension ContentArrayBuilder {
    static func buildExpression(_ expression: GitHubSearch) -> [ContentItem] {
        return expression.toItems()
    }
}

struct GitHubSearchData {
    static func makeSearchQuery(q: String) -> String {
    return """
{
  search(query: "\(q)", type: ISSUE, first: 100) {
    nodes {
      ... on PullRequest {
        id
        author {
          login
        }
        title
        number
        url
        updatedAt
        createdAt
        repository {
          name
          owner {
            login
          }
        }
        authorAssociation
        latestReviews(first: 100) {
          nodes {
            state
            author {
              login
            }
          }
        }
        commits(last: 1) {
          nodes {
            commit {
              status {
                context(name: "") {
                  id
                }
                id
                state
              }
            }
          }
        }
      }
      ... on Issue {
        id
        author {
          login
        }
        title
        number
        url
        updatedAt
        createdAt
        repository {
          name
          owner {
            login
          }
        }
        authorAssociation
      }
    }
  }
}
"""
    }
    
    struct Response: Codable {
        let data: Data
        
        struct Data: Codable {
            let search: Search
        }
        
        struct Search: Codable {
            let nodes: [Node]
            
            struct Node: Codable {
                let id: String
                let title: String
                let number: Int
                let url: String
                
                let author: Author?
                
                let createdAt: Date
                let updatedAt: Date
                
                let authorAssociation: String
                
                let repository: Repository
                
                // Pull Request Only
                let commits: Commits?
                let latestReviews: LatestReviews?
            }
            
            struct Repository: Codable {
                let name: String
                let owner: Owner
            }
            
            struct Author: Codable {
                let login: String
            }
            
            struct Owner: Codable {
                let login: String
            }
            
            struct LatestReviews: Codable {
                let nodes: [Node]

                struct Node: Codable {
                    let state: String
                    let author: Author
                }
            }
            
            struct Commits: Codable {
                let nodes: [Node]

                struct Node: Codable {
                    let commit: Commit

                    struct Commit: Codable {
                        let status: Status?

                        struct Status: Codable {
                            let state: String
                        }
                    }
                }
            }
            
            
        }
    }
}

extension GitHubSearchData.Response.Search.Node {
    var asItem: ContentItem {
        return ContentItem(title: _title, subtitle: _subtitle, extras: _extras, actions: _actions)
    }
    
    private var _title: String {
        return "#\(String(self.number)) - \(self.title)"
    }
    
    private var _subtitle: String? {
        let extra = " on \(repository.owner.login)/\(repository.name)"
        return "\(self.createdAt.timeAgoDisplay()) by \(self.author?.login ?? "UNKNOWN")\(extra)"
    }
    
    private var _extras: [String] {
        var things = [String]()
        
        if let status = commits?.nodes.first?.commit.status?.state {
            things.append("Tests - \(status)")
        }
        
        var dict = [String: Int]()
        for node in (self.latestReviews?.nodes ?? []) {
            let count = dict[node.state] ?? 0
            dict[node.state] = count + 1
        }
        
        let thing = Array(dict.keys).sorted().map { key in
            return "\(dict[key]!) \(key)"
        }
        if !thing.isEmpty {
            things.append(thing.joined(separator: ", "))
        }
        
        return things
    }
    
    private var _actions: [Output.Action] {
        return []
    }
}
