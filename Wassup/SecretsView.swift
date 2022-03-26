//
//  SecretsView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/26/22.
//

import SwiftUI

struct SecretsView: View {
    @Binding var text: String

    init(text: Binding<String>) {
        self._text = text
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            TextEditor(text: $text)
                .font(Font.system(size: 14, weight: .regular, design: .monospaced))
                .padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
