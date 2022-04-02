//
//  Output.swift
//  Wassup
//
//  Created by Josh Holtz on 4/1/22.
//

import Foundation

struct Output: Codable {
    let dashboards: [Dashboard]
    
    struct Dashboard: Codable {
        let name: String
        let panes: [Pane]
    }
    
    struct Pane: Codable {
        enum CountAlert: String, Codable {
            case none, low, medium, high
        }
        
        let name: String
        let alert: CountAlert
        var x: Int
        var y: Int
        var width: Int
        var height: Int
        let items: [Item]
    }
    
    struct Item: Codable {
        let title: String
        let subtitle: String?
        let extras: [String]
        
        let meta: String?
        
        let actions: [Output.Action]
    }
    
    struct Action: Codable {
        let name: String?
        let image: String?
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
