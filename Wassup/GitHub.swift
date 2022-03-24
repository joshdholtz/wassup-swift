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
    var itemTitle: String {
        return "#\(String(self.number)) - \(self.title)"
    }
    
    var itemSubtitle: String? {
        return "\(self.createdAt.timeAgoDisplay()) by \(self.user.login)"
    }
    
    var actions: [Output.Action] {
        return []
    }
}
