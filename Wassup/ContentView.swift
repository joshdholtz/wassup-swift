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
    @State var settingsView = false
    @State var lastRefreshed: Date = Date.now
    
    @State var panes: [Output.Pane] = []
    
    let timer = Timer.publish(every: 60 * 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if editView {
                EditView(text: $scriptText, secrets: secretsText)
            } else if secretsView {
                SecretsView(text: $secretsText)
            } else if settingsView {
                SettingsView()
            } else {
                DashboardView(panes: $panes,
                              scriptText: $scriptText,
                              secretsText: $secretsText,
                              lastRefreshed: $lastRefreshed)
            }
            
            Divider()
            
            HStack {
                if !editView && !secretsView && !settingsView {
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
                    
                    Button {
                        self.settingsView = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                
                if editView || secretsView || settingsView {
                    Button {
                        self.editView = false
                        self.secretsView = false
                        self.settingsView = false
                    } label: {
                        Label("Save", systemImage: "square.grid.2x2")
                    }
                }
                
                Spacer()
                
                if !editView && !secretsView && !settingsView {
                    Text("Refreshed at ") + Text(lastRefreshed, style: .time)
                    Button {
                        Task {
                            await refresh()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }.padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 10)
        }
        .background(Color(hex: "#301934"))
        .task {
            await refresh()
        }
        .onReceive(timer) { input in
            print("should refresh")
            Task {
                await refresh()
            }
        }
    }
    
    func refresh() async {
        if self.scriptText == "" {
            return
        }
        
        do {
            let exe = Executor()
            let output = try exe.load(script: scriptText, secrets: secretsText)
            
            // TODO: Fix for multiple dashboards
            let onePanes = output.dashboards.first?.panes ?? []
            
            var counts = [Output.Pane.CountAlert: Int]()
            for pane in onePanes {
                let count = counts[pane.alert] ?? 0
                counts[pane.alert] = count + pane.items.count
            }
            
            NotificationCenter.default.post(name: .wassupNewData, object: nil, userInfo: counts)
            
            self.lastRefreshed = Date.now
            self.panes = onePanes
        } catch {
            print("Refresh error: \(error)")
        }
    }
}

struct DashboardView: View {
    
    @Binding var panes: [Output.Pane]
    @Binding var scriptText: String
    @Binding var secretsText: String
    @Binding var lastRefreshed: Date
    
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
    
    init(panes: Binding<[Output.Pane]>, scriptText: Binding<String>, secretsText: Binding<String>, lastRefreshed: Binding<Date>) {
        self._panes = panes
        self._scriptText = scriptText
        self._secretsText = secretsText
        self._lastRefreshed = lastRefreshed
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading) {
                if !self.panes.isEmpty {
                    
                    ZStack {
                        GeometryReader { proxy in
                            ForEach(self.panes, id: \.self.name) { pane in
                                PaneView(pane: pane)
                                    .padding(.all, 5)
                                    .frame(width: proxy.size.width * (Double(pane.width) / maxWidth),
                                           height: proxy.size.height * (Double(pane.height) / maxHeight))
                                    .offset(x: (proxy.size.width / maxWidth) * CGFloat(pane.x),
                                            y: (proxy.size.height / maxHeight) * CGFloat(pane.y))
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    Text("Loading...")
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 10)
                .padding(.top, 10)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaneView: View {
    let pane: Output.Pane
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(pane.name)
                    .multilineTextAlignment(.leading)
                    .font(.title)
                    .padding(.trailing, 20)
                Spacer()
            }.frame(maxWidth: .infinity)
            ScrollView {
                ForEach(pane.items, id: \.self.title) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(item.title)
                                    .font(.title3)
//                                    .opacity(0.85)
                                Spacer()
                            }
                            if let subtitle = item.subtitle {
                                HStack {
                                    Text(subtitle)
                                        .font(.callout)
                                        .opacity(0.85)
                                    Spacer()
                                }
                            }

                            ForEach(item.extras, id: \.self) { extra in
                                HStack {
                                    Text(extra)
                                        .font(.callout)
                                        .opacity(0.85)
                                    Spacer()
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                        
                        VStack {
                            Actions(item: item)
                            Spacer()
                        }.padding(.top, 5)

                    }
                }.padding(.trailing, 20)
            }.frame(maxWidth: .infinity)
        }.frame(maxWidth: .infinity)
            .padding(.leading, 20)
            .padding(.vertical, 20)
            .background(Color.black.opacity(0.1))
            .cornerRadius(4)
    }
}

struct Actions: View {
    @Environment(\.openURL) var openURL
    
    let item: Output.Item
    
    var body: some View {
        HStack() {
            ForEach(Array(item.actions.enumerated()), id: \.offset) { index, action in
                Button {
                    switch action.value {
                    case .url(let url):
                        if let url = URL(string: url) {
                            openURL(url)
                        }
                    case .shell(let command):
                        let _ = try? shellOut(to: command)
                    }
                } label: {
                    HStack {
                        if let image = action.image {
                            Image(systemName: image)
                        }
                        if let name = action.name {
                            Text(name)
                        }
                    }
                }
            }
        }
    }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label.foregroundColor(.white)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color(hex: "#301934").cornerRadius(4))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
