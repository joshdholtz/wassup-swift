//
//  GitHub.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

struct GitHub {
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
    
    struct GraphSearchResponse: Codable {
        let data: UghData
        
        struct UghData: Codable {
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
    
    struct SearchResponse: Codable {
        let totalCount: Int
        let incompleteResults: Bool
        let items: [Item]
        
        struct Item: Codable, Identifiable {
            let repositoryUrl: String
            let htmlUrl: String
            let id: Int
            let number: Int
            let title: String
            let user: User
            let createdAt: Date
            
            var org: String? {
                return URL(string: repositoryUrl)?.pathComponents.suffix(2).first
            }
            
            var repo: String? {
                return URL(string: repositoryUrl)?.pathComponents.last
            }
        }
    }
    
    struct User: Codable {
        let login: String
    }
}

extension GitHub.SearchResponse.Item: ContentItem {
    var itemTitle: String {
        return "#\(String(self.number)) - \(self.title)"
    }
    
    var itemSubtitle: String? {
        var extra = ""
        if let org = org, let repo = repo {
            extra = " on \(org)/\(repo)"
        }
        
        return "\(self.createdAt.timeAgoDisplay()) by \(self.user.login)\(extra)"
    }
    
    var extras: [String] {
        return []
    }
    
    var actions: [Output.Action] {
        return []
    }
}

extension GitHub.GraphSearchResponse.Search.Node: ContentItem {
    var itemTitle: String {
        return "#\(String(self.number)) - \(self.title)"
    }
    
    var itemSubtitle: String? {
        let extra = " on \(repository.owner.login)/\(repository.name)"
        return "\(self.createdAt.timeAgoDisplay()) by \(self.author?.login ?? "UNKNOWN")\(extra)"
    }
    
    var extras: [String] {
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
    
    var actions: [Output.Action] {
        return []
    }
}
