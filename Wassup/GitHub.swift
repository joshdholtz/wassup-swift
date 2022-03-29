//
//  GitHub.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

struct GitHub {
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
    
    var actions: [Output.Action] {
        return []
    }
}
