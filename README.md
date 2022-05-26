# Wassup

<img width="1432" alt="Screen Shot 2022-03-29 at 11 02 53 PM" src="https://user-images.githubusercontent.com/401294/160749056-07ffef1a-b57d-4106-8df1-8c7df5903657.png">

## Dashboard Configuration
```swift
Dashboard("fastlane") {
    Pane("Open PRs") {
        GitHubSearch("repo:fastlane/fastlane is:pr is:open")
    }.frame(x: 0, y: 0, width: 1, height: 2)

    Pane("High Activity Issues (7 Days, 10+ interactions)", alert: .high) {
        GitHubSearch("repo:fastlane/fastlane is:issue is:open interactions:>10", [.createdLessThan(7)])
    }.frame(x: 1, y: 0)

    Pane("My PRs") {
        GitHubSearch("repo:fastlane/fastlane is:pr is:open author:joshdholtz")
    }.frame(x: 1, y: 1)

    Pane("fastlane-community PRs") {
        GitHubSearch("repo:fastlane-community/xcov is:pr is:open")
        GitHubSearch("repo:fastlane-community/danger-xcov is:pr is:open")
    }.frame(x: 2, y: 0, width: 1, height: 2)
}
```

## Secret Settings
```shell
GITHUB_USERNAME=your_username
GITHUB_API_KEY=your_api_key
```
