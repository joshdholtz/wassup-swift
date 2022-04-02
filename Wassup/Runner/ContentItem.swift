//
//  ContentItem.swift
//  Wassup
//
//  Created by Josh Holtz on 4/1/22.
//

import Foundation



struct ContentItem: Codable {
    let title: String
    let subtitle: String?
    let extras: [String]
    let actions: [Output.Action]
}

enum ActionValue: Codable {
    case url(String), shell(String)
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

extension ContentItem {
    func action(action: (Self) -> (ActionValue)) -> Self {
        return self
    }
}
