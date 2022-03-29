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
            if editView {
                EditView(text: $scriptText, secrets: secretsText)
            } else if secretsView {
                SecretsView(text: $secretsText)
            } else {
                DashboardView(scriptText: $scriptText, secretsText: $secretsText, editView: $editView, secretsView: $secretsView)
            }
        }
    }
}

struct DashboardView: View {
    
    @Binding var scriptText: String
    @Binding var secretsText: String
    
    @Binding var editView: Bool
    @Binding var secretsView: Bool
    
    @State var panes: [Output.Pane] = []
    
    @State var selectedPane = 0
    @State var lastRefreshed: Date = Date.now
    
    let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()
    
    var maxWidth: Double {
        var max = 0
        
        for pane in self.panes {
            let v = pane.x + pane.width
            if v > max {
                max = v
            }
        }
        
        return Double(max)
    }
    
    var maxHeight: Double {
        var max = 0
        
        for pane in self.panes {
            let v = pane.y + pane.height
            if v > max {
                max = v
            }
        }
        
        return Double(max)
    }
    
    init(scriptText: Binding<String>, secretsText: Binding<String>, editView: Binding<Bool>, secretsView: Binding<Bool>) {
        self._scriptText = scriptText
        self._secretsText = secretsText
        self._editView = editView
        self._secretsView = secretsView
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading) {
                if !self.panes.isEmpty {
                    
                    ZStack {
                        GeometryReader { proxy in
                            ForEach(self.panes, id: \.self.name) { pane in
                                PaneView(pane: pane)
                                    .padding()
                                    .frame(width: proxy.size.width * (Double(pane.width) / maxWidth),
                                           height: proxy.size.height * (Double(pane.height) / maxHeight))
                                    .offset(x: (proxy.size.width / maxWidth) * CGFloat(pane.x),
                                            y: (proxy.size.height / maxHeight) * CGFloat(pane.y))
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    HStack {
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
                .frame(maxWidth: .infinity)
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
                }.padding(.trailing, 20)
            }.frame(maxWidth: .infinity)
        }.frame(maxWidth: .infinity)
    }
}
