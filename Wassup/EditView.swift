//
//  EditView.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import SwiftUI

import CodeEditor

struct EditView: View {
    
    @Binding var text: String
    @State var fontSize: CGFloat = 14
    var secrets: String
    
    @State var isRunning = false
    @State var validateOutput: String? = nil

    init(text: Binding<String>, secrets: String) {
        self._text = text
        self.secrets = secrets
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CodeEditor(source: self.$text,
                       language: .swift,
                       theme: .default,
                       fontSize: self.$fontSize,
                       flags: [ .selectable, .editable, .smartIndent])
                .padding()
            
            Button {
                self.isRunning = true
                do {
                    let exe = Executor()
                    let output = try exe.load(script: text, secrets: secrets)
                    print("OUTPUT BELOW")
                    print(output)
                    
                    self.validateOutput = "Success"
                    self.isRunning = false
                } catch {
                    print("Edit run error: \(error)")
                    self.validateOutput = "Error: \(error)"
                    self.isRunning = false
                }
            } label: {
                Text(isRunning ? "Running" : "Run")
            }
            
            if let output = self.validateOutput {
                Text(output)
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
