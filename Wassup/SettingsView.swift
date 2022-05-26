//
//  SettingsView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/29/22.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("windowWidth")
    private var windowWidth: Int = 800
    
    @AppStorage("windowHeight")
    private var windowHeight: Int = 400
    
    var body: some View {
        Form {
            HStack(alignment: .firstTextBaseline) {
                Text("Toggle Window:")
                KeyboardShortcuts.Recorder(for: .toggleWindow)
            }
            
            Stepper {
                Text("Width: \(windowWidth)")
            } onIncrement: {
                self.windowWidth += 100
                NotificationCenter.default.post(name: .wassupWindowSizeChanged, object: nil)
            } onDecrement: {
                self.windowWidth -= 100
                NotificationCenter.default.post(name: .wassupWindowSizeChanged, object: nil)
            }
            
            Stepper {
                Text("Height: \(windowHeight)")
            } onIncrement: {
                self.windowHeight += 100
                NotificationCenter.default.post(name: .wassupWindowSizeChanged, object: nil)
            } onDecrement: {
                self.windowHeight -= 100
                NotificationCenter.default.post(name: .wassupWindowSizeChanged, object: nil)
            }
            
            Button {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.updaterController.checkForUpdates(nil)
                }
            } label: {
                Text("Check for updates")
            }
            Button {
                NSApp.terminate(self)
            } label: {
                Text("Quit")
            }

        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
