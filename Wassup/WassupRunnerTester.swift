//
//  WassupRunnerTester.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation

func thing() {
    let dashboard = Dashboard("fastlane") {
        Pane("Open PRs") {
            GitHubSearch("repo:fastlane/fastlane is:pr is:open")
                .action("Open") { thing in
                    .url(thing.url)
                }
        }
        Pane("High Activity Issues (7 Days, 10+ interactions)", alert: .high) {
            GitHubSearch("repo:fastlane/fastlane is:issue is:open interactions:>10", [.createdLessThan(7)])
        }
        Pane("My PRs") {
            GitHubSearch("repo:fastlane/fastlane is:pr is:open author:joshdholtz")
        }
        Pane("fastlane-community PRs") {
            GitHubSearch("repo:fastlane-community/xcov is:pr is:open")
            GitHubSearch("repo:fastlane-community/danger-xcov is:pr is:open")
        }
        Pane("Builder Test") {
            Item("A title", subtitle: "A subtitle")
            Item("Only a title")
            Item("Another title", subtitle: "Another subtitle")
        }
    }
    
    if let output = try? dashboard.toString() {
        print(output)
    }
}
