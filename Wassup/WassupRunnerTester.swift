//
//  WassupRunnerTester.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

func thing() {
    Dashboard("fastlane") {
        Pane("Open PRs") {
            GitHub.Search("repo:fastlane/fastlane is:pr is:open")
                .action(label: "Open") { thing in
                    .url(thing.url)
                }
        }
        Pane("High Activity Issues (7 Days, 10+ interactions)", alert: .high) {
            GitHub.Search("repo:fastlane/fastlane is:issue is:open interactions:>10", [.createdLessThan(7)])
        }
        Pane("My PRs") {
            GitHub.Search("repo:fastlane/fastlane is:pr is:open author:joshdholtz")
                .action(label: "Copy") { .shell("echo -n \"\($0)\" | pbcopy") }
        }
        Pane("fastlane-community PRs") {
            GitHub.Search("repo:fastlane-community/xcov is:pr is:open")
            GitHub.Search("repo:fastlane-community/danger-xcov is:pr is:open")
        }
        Pane("Repos") {
            GitHub.Repos("org:fastlane-community")
        }
//        Pane("Builder Test") {
//            Item("A title", subtitle: "A subtitle")
//            Item("Only a title")
//            Item("Another title", subtitle: "Another subtitle")
//        }
    }
    
    let output = Output(dashboards: Dashboards.all.map({$0.toOutput()}))
    if let outputString = output.toString() {
        print(outputString)
    }
}
