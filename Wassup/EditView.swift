//
//  EditView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import SwiftUI

struct EditView: View {
    
    @Binding var text: String
    var secrets: String

    init(text: Binding<String>, secrets: String) {
        self._text = text
        self.secrets = secrets
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            TextEditor(text: $text)
                .font(Font.system(size: 14, weight: .regular, design: .monospaced))
                .padding()
            Button {
                do {
                    let exe = Executor()
                    let output = try exe.load(script: text, secrets: secrets)
                    print("OUTPUT BELOW")
                    print(output)
                } catch {
                    print("Edit run error: \(error)")
                }
            } label: {
                Text("Run")
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
    
}


// HACK to work-around the smart quote issue
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}
