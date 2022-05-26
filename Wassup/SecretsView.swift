//
//  SecretsView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/26/22.
//

import SwiftUI

import CodeEditor

struct SecretsView: View {
    @Binding var text: String
    @State var fontSize: CGFloat = 14

    init(text: Binding<String>) {
        self._text = text
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            CodeEditor(source: self.$text,
                       language: .swift,
                       theme: .default,
                       fontSize: self.$fontSize,
                       flags: [ .selectable, .editable, .smartIndent])
                .padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
