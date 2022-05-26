//
//  GitHubRepos.swift
//  Wassup
//
//  Created by Josh Holtz on 4/22/22.
//

import Foundation

extension GitHub {
    struct Repos: ContentBuilder {
        var q: String
        
        var actions: [(String?, String?, GitHubReposAction)]? = nil
        
        var defaultActions: [(String?, String?, GitHubReposAction)] =  [(nil, "square.and.arrow.up", { .url($0.url) })]
        
        init(_ q: String, _ actions: [(String?, String?, GitHubReposAction)]? = nil) {
            self.q = q
            self.actions = actions ?? defaultActions
        }
        
        func toItems() -> [ContentItem] {
            do {
                let newQ = q
                
                let githubUsername = ProcessInfo.processInfo.environment["GITHUB_USERNAME"]!.trimmingCharacters(in: .whitespacesAndNewlines)
                let githubApiKey = ProcessInfo.processInfo.environment["GITHUB_API_KEY"]!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let url = "https://api.github.com/graphql"
                let query = GitHubReposData.makeSearchQuery(q: newQ)
                
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

                let decodedResponse = try decoder.decode(GitHubReposData.Response.self, from: data!)
                return decodedResponse.data.search.nodes.map { item in
                    let contentItem = item.asItem
                    
                    let actions = self.actions ?? []
                    
                    return ContentItem(
                        title: contentItem.title,
                        subtitle: contentItem.subtitle,
                        extras: [],
    //                    contentItem: item,
                        actions: actions.map({ (key: String?, image: String?, value: GitHubReposAction) in
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
}

typealias GitHubReposAction = (GitHubReposData.Response.Search.Node) -> (ActionValue)
extension GitHub.Repos {
    func action(label name: String? = nil, image: String? = nil, clearPrevious: Bool = false, action: @escaping GitHubReposAction) -> Self {
        let actions = (clearPrevious ? [] : self.actions ?? []) + [(name, image, action)]
        
        return GitHub.Repos(self.q, actions)
    }
}

extension ContentArrayBuilder {
    static func buildExpression(_ expression: GitHub.Repos) -> [ContentItem] {
        return expression.toItems()
    }
}

struct GitHubReposData {
    static func makeSearchQuery(q: String) -> String {
    return """
{
  search(query: "\(q)", type: REPOSITORY, first: 100) {
    nodes {
      ... on Repository {
        id
        name
        url
        owner {
          login
        }
        releases(first: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
          nodes {
            name
            tagName
            url
          }
        }
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
                let name: String
                let url: String
                
                let owner: Owner
                
                let releases: Releases
            }
            
            struct Owner: Codable {
                let login: String
            }
            
            struct Releases: Codable {
                let nodes: [Node]

                struct Node: Codable {
                    let name: String
                    let tagName: String
                    let url: String
                }
            }
        }
    }
}

extension GitHubReposData.Response.Search.Node {
    var asItem: ContentItem {
        return ContentItem(title: _title, subtitle: _subtitle, extras: _extras, actions: _actions)
    }
    
    private var _title: String {
        return self.name
    }
    
    private var _subtitle: String? {
        return self.owner.login
    }
    
    private var _extras: [String] {
        let things = [String]()
        
        return things
    }
    
    private var _actions: [Output.Action] {
        return []
    }
}
