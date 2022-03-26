//
//  ContentView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/16/22.
//

import SwiftUI

import ShellOut

struct ContentView: View {
    @AppStorage("scriptTextV1")
    private var scriptText: String = ""
    
    @AppStorage("secretsTextV1")
    private var secretsText: String = ""
    
    @State var editView = false
    @State var secretsView = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                if !editView && !secretsView {
                    Button {
                        self.editView = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle.fill")
                    }
                
                    Button {
                        self.secretsView = true
                    } label: {
                        Label("Secrets", systemImage: "lock.fill")
                    }
                }
                
                if editView || secretsView {
                    Button {
                        self.editView = false
                        self.secretsView = false
                    } label: {
                        Label("Save", systemImage: "square.grid.2x2")
                    }
                }
            }.padding()
            
            if editView {
                EditView(text: $scriptText, secrets: secretsText)
            } else if secretsView {
                SecretsView(text: $secretsText)
            } else {
                DashboardView(scriptText: $scriptText, secretsText: $secretsText)
            }
        }
    }
}

struct DashboardView: View {
    
    @Binding var scriptText: String
    @Binding var secretsText: String
    
    @State var panes: [Output.Pane] = []
    
    @State var selectedPane = 0
    @State var lastRefreshed: Date = Date.now
    
    let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    init(scriptText: Binding<String>, secretsText: Binding<String>) {
        self._scriptText = scriptText
        self._secretsText = secretsText
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading) {
                if !self.panes.isEmpty, let pane = self.panes[self.selectedPane] {
                    PaneView(pane: pane)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    HStack {
                        ForEach((1...self.panes.count), id: \.self) { index in
                            Button {
                                self.selectedPane = index - 1
                            } label: {
                                Text("\(index)")
                            }
                        }
                        
                        Spacer()
                        
                        Text("Refreshed at ") + Text(lastRefreshed, style: .time)
                        Button {
                            Task {
                                await refresh()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
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
        if self.scriptText == "" {
            return
        }
        
        do {
            let exe = Executor()
            let output = try exe.load(script: scriptText, secrets: secretsText)
            
            var counts = [Output.Pane.CountAlert: Int]()
            for pane in output.panes {
                let count = counts[pane.alert] ?? 0
                counts[pane.alert] = count + pane.items.count
            }
            
            NotificationCenter.default.post(name: .wassupNewData, object: nil, userInfo: counts)
            
            self.lastRefreshed = Date.now
            self.panes = output.panes
        } catch {
            print("Refresh error: \(error)")
        }
    }
}

struct PaneView: View {
    @Environment(\.openURL) var openURL
    
    let pane: Output.Pane
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(pane.name)
                .font(.title)
            ScrollView {
                ForEach(pane.items, id: \.self.title) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.title2)
                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(.title3)
                            }
                        }
                        Spacer()
                        
                        ForEach(item.actions, id: \.self.name) { action in
                            Button {
                                switch action.value {
                                case .url(let url):
                                    if let url = URL(string: url) {
                                        openURL(url)
                                    }
                                case .shell(_):
                                    print("nothing yet")
                                }
    //                            openURL(URL(string: item.htmlUrl)!)
                            } label: {
                                Text(action.name)
                            }
                        }

                    }
                }
            }
        }
    }
}
