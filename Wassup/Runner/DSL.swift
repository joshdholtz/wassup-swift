//
//  DSL.swift
//  Wassup
//
//  Created by Josh Holtz on 4/1/22.
//

import Foundation
    
protocol ContentBuilder {
    
}

class Dashboards {
    static var all: [Dashboard] = []
}

struct Dashboard {
    var name: String
    @PaneArrayBuilder var panes: () -> [Pane]
    
    init(_ name: String, @PaneArrayBuilder panes: @escaping () -> [Pane]) {
        self.name = name
        self.panes = panes
        
        Dashboards.all.append(self)
    }
}

struct Pane {
    var name: String
    var alert: Output.Pane.CountAlert
    @ContentArrayBuilder var contents: () -> [ContentItem]
    
    var x: Int?
    var y: Int?
    var width: Int
    var height: Int
    
    init(_ name: String, alert:  Output.Pane.CountAlert = .none, x: Int? = nil, y: Int? = nil, width: Int = 1, height: Int = 1, @ContentArrayBuilder contents: @escaping () -> [ContentItem]) {
        self.name = name
        self.alert = alert
        
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        
        self.contents = contents
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

    static func buildExpression(_ expression: ContentItem) -> [ContentItem] {
        return [expression]
    }
}

extension Pane {
    func frame(x: Int, y: Int, width: Int = 1, height: Int = 1) -> Self {
        return Pane(self.name, alert: self.alert, x: x, y: y, width: width, height: height, contents: self.contents)
    }
}

extension Dashboard {
    func toOutput() -> Output.Dashboard {
        let panes: [Output.Pane] = positionedPanes.map { (pane, x, y) -> Output.Pane in
            let outputItems: [Output.Item] = pane.contents().map { contentItem -> Output.Item in
                let title = contentItem.title
                let subtitle = contentItem.subtitle
                let extras = contentItem.extras
                let meta = contentItem.toString()
                let actions = contentItem.actions
                
                return Output.Item(title: title, subtitle: subtitle, extras: extras, meta: meta, actions: actions)
            }
            
            let outputPane = Output.Pane(name: pane.name,
                                         alert: pane.alert,
                                         x: x,
                                         y: y,
                                         width: pane.width,
                                         height: pane.height,
                                         items: outputItems)
            
            return outputPane
        }
        
        let output = Output.Dashboard(name: name, panes: panes)
        return output
    }
    
    var positionedPanes: [(Pane, Int, Int)] {
        var maxWidth: Int = 0
        var maxHeight: Int = 0
        
        var positioned: [(Pane, Int, Int)] = []
        
        var toBePlaced: [Pane] = []
        
        for pane in self.panes() {
            if let x = pane.x, (x + pane.width) > maxWidth {
                maxWidth = x + pane.width
            }
            if let y = pane.y, (y + pane.height) > maxHeight {
                maxHeight = y + pane.height
            }
            
            if let x = pane.x, let y = pane.y {
                positioned.append((pane, x, y))
            } else {
                toBePlaced.append(pane)
            }
        }
        
        if maxWidth == 0 && maxHeight == 0 {
            maxWidth = Int(ceil(sqrt(Double(toBePlaced.count))))
            maxHeight = maxWidth
            
            let chunks = toBePlaced.chunked(into: maxHeight)
            for (row, panes) in chunks.enumerated() {
                for (col, pane) in panes.enumerated() {
                    positioned.append((pane, col, row))
                }
            }
        }
        
        return positioned
    }
}
