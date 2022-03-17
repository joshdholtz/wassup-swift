//
//  ContentView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/16/22.
//

import SwiftUI

struct ContentView: View {
    
    @State var pages: [(String, GitHub.SearchResponse, Bool)] = []
    
    @State var selectedPage = 0
    @State var lastRefreshed: Date = Date.now
    
    let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack {
                Text("Refreshed at ") + Text(lastRefreshed, style: .time)
                
                Button {
                    Task {
                        self.pages = []
                        await refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }.padding()

            
            VStack(alignment: .leading) {
                if !self.pages.isEmpty, let page = self.pages[self.selectedPage] {
                    PageView(title: page.0, searchResponse: page.1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    HStack {
                        ForEach((1...self.pages.count), id: \.self) { index in
                            Button {
                                self.selectedPage = index - 1
                            } label: {
                                Text("\(index)")
                            }
                        }
                    }
                    
                } else {
                    Text("Loading...")
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                await refresh()
            }
            .onReceive(timer) { input in
                print("should refresh")
                Task {
                    await refresh()
                }
            }
//            .onReceive(NotificationCenter.default.publisher(for: .popoverDidShow)) { _ in
//                DispatchQueue.main.async {
//                    self.lastRefreshedText = self.lastRefreshed.timeAgoDisplay()
//                }
//            }
    }
    
    func refresh() async {
        do {
            let pagesData = [
//                ("Wassup", "repo:joshdholtz/wassup-swift+is:issue+is:open", true),
                ("Reviews Requested", "org:RevenueCat+is:pr+is:open+review-requested:joshdholtz", true),
                ("iOS PRs", "repo:RevenueCat/purchases-ios+is:pr+is:open", false),
                ("Android PRs", "repo:RevenueCat/purchases-android+is:pr+is:open", false),
                ("React Native PRs", "repo:RevenueCat/react-native-purchases+is:pr+is:open", false),
                ("Flutter PRs", "repo:RevenueCat/purchases-flutter+is:pr+is:open", false),
                ("Cordova PRs", "repo:RevenueCat/cordova-plugin-purchases+is:pr+is:open", false),
                ("Unity PRs", "repo:RevenueCat/purchases-unity+is:pr+is:open", false)
            ]
            
            let pages = try await withThrowingTaskGroup(of: (Int, String, GitHub.SearchResponse, Bool).self) { group -> [(String, GitHub.SearchResponse, Bool)] in
                for (index, page) in pagesData.enumerated() {
                    group.addTask{
                        let result = try await search(query: page.1)
                        return (index, page.0, result, page.2)
                    }
                }

                var results = [(Int, String, GitHub.SearchResponse, Bool)]()

                for try await (index, title, result, alert) in group {
                    results.append((index, title, result, alert))
                }

                return results.sorted { a, b in
                    return a.0 < b.0
                }.map { ($0.1, $0.2, $0.3) }
            }
            
            var alert = false
            for page in pages {
                if page.2 == true && !page.1.items.isEmpty {
                    alert = true
                }
            }
            
            if alert {
                NotificationCenter.default.post(name: .wassupNewData, object: nil)
            } else {
                NotificationCenter.default.post(name: .wassupResetData, object: nil)
            }
            
            self.pages = pages
            self.lastRefreshed = Date.now
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    let githubUsername = "joshdholtz"
    let githubAccessToken = "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"
    
    // org:fastlane+is:pr+is:open
    // org:RevenueCat+is:pr+is:open+review-requested:joshdholtz
    func search(query: String) async throws -> GitHub.SearchResponse {
        let url = URL(string: "https://api.github.com/search/issues?q=\(query)")
        var request = URLRequest(url: url!)
        
        let basic = "\(githubUsername):\(githubAccessToken)".toBase64()
        request.addValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
//        print("Response: \(String(data: data, encoding: .utf8))")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let decodedResponse = try decoder.decode(GitHub.SearchResponse.self, from: data)
        return decodedResponse
    }
}

struct PageView: View {
    @Environment(\.openURL) var openURL
    
    let title: String
    let searchResponse: GitHub.SearchResponse
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)
            ScrollView {
                ForEach(searchResponse.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("#\(String(item.number)) - \(item.title)")
                                .font(.title2)
                            Text("\(item.createdAt.timeAgoDisplay()) by \(item.user.login)")
                                .font(.title3)
                        }
                        Spacer()
                        Button {
                            openURL(URL(string: item.htmlUrl)!)
                        } label: {
                            Text("Open")
                        }

                    }
                }
            }
        }
    }
}

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

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
