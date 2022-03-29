//
//  SettingsView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/29/22.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            HStack(alignment: .firstTextBaseline) {
                Text("Toggle Window:")
                KeyboardShortcuts.Recorder(for: .toggleWindow)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
