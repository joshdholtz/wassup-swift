# Wassup

**Wassup** is a flexible and customizable dashboard for showing GitHub data. The dashboard is configured through a custom Swift DSL and refreshed every 5 minutes. Panes can also be set with different alert levels. If any content shows up in those panes, the number of items will show up in the menu bar icon to alert the user that something needs attention).

https://user-images.githubusercontent.com/401294/170400835-0762658c-04c9-4505-9def-e9fb2ad6531a.mov

## Setup

### Dashboard Configuration

This is an example DSL that is used to configure the dashboard.

`Pane`'s are given a title, a body of content, and a frame. A frame requires `x` and `y` and have a default `width` and `height` of `1`.

The only available data generator right now is `GitHubSearch`. All options for this query can be found in [GitHub's search issues and pull requests](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests) doc.

```swift
Dashboard("fastlane") {
    Pane("Open PRs") {
        GitHubSearch("repo:fastlane/fastlane is:pr is:open", showExtras: true)
    }.frame(x: 0, y: 0, width: 1, height: 2)

    Pane("High Activity Issues (7 Days, 10+ interactions)", alert: .high) {
        GitHubSearch("repo:fastlane/fastlane is:issue is:open interactions:>10", [.createdLessThan(7)])
	}.frame(x: 1, y: 0)

    Pane("My PRs") {
        GitHubSearch("repo:fastlane/fastlane is:pr is:open author:joshdholtz", showExtras: true)			
            .action(image: "square.fill.on.square") { .copy($0.url) }
    }.frame(x: 1, y: 1)

    Pane("fastlane-community PRs") {
        GitHubSearch("repo:fastlane-community/xcov is:pr is:open")
        GitHubSearch("repo:fastlane-community/danger-xcov is:pr is:open")  
    }.frame(x: 2, y: 0, width: 1, height: 2)
}
```

### Secret Settings

These are the (somewhat) required secrets you will need to set to avoid getting rate limited by GitHub. You can generate your GitHub API Key in the [Personal Access Token](https://github.com/settings/tokens) section of your settings.

```shell
GITHUB_USERNAME=your_username
GITHUB_API_KEY=your_api_key
```

## SwiftUI Series Information

This macOS app doesn't do a lot of crazy stuff with SwiftUI. However...
- [Status bar item](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/AppDelegate.swift#L15-L63) is a SwiftUI view
- This would have been much more difficult to build without SwiftUI
- The DSL for the dashboard configuration is **HIGHLY** inspired by SwiftUI
  - I got some experience at how SwiftUI works by building a custom DSL
  - The dashboard configuration is a fun, scriptable, and (hopefully) natural feeling to users because of its similarity to SwiftUI

### How This Works

#### There are two parts to this:
1. A SwiftUI app
2. A Swift script that runs the DSL

#### These parts share both:
1. The [DSL](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/Runner/DSL.swift)
2. A [data structure](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/Runner/Output.swift) that uses `Codable` objects that allow the SwiftUI and the Swift script to communicate

#### The steps: 
1. DSL is written by user in SwiftUI app
2. DSL is then [built and run](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/WassupExecutor.swift) with `swift` CLI (shelled out using [ShellOut](https://github.com/JohnSundell/ShellOut))
    - The script fetches all the data from the panes and generates a nice codable data structure
    - The data structure is encoded to a JSON string a written to STDOUT for the SwiftUI app to read
3. [SwiftUI app waits](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/ContentView.swift#L117-L143) for the JSON response from the `swift` CLI and then decodes using the same data structure
4. This data structure is then [rendered into the SwiftUI dashboard](https://github.com/joshdholtz/wassup-swift/blob/main/Wassup/ContentView.swift#L145-L211) you see in the screenshot above

#### Swift CLI Script
The Swift CLI script is generated with the DSL, data structure, and runner in the Xcode build phase. This ensures that the SwiftUI app and Swift CLI script are always using the same versions in each build.
<img width="924" alt="Screen Shot 2022-05-25 at 8 59 46 PM" src="https://user-images.githubusercontent.com/401294/170399909-71ad1366-4ff8-41e5-8907-da47fe6fd532.png">

