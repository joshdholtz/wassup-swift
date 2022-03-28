//
//  WassupExecutor.swift
//  Wassup
//
//  Created by Josh Holtz on 3/18/22.
//

import Foundation
import ShellOut

struct Executor {
    func load(script: String, secrets: String) throws -> Output {
        let secretsCLI = secrets.split(whereSeparator: \.isNewline).map { substring -> String in
            let thing = String(substring)
            return thing
        }.joined(separator: " ")
        
        let swiftFileURL = try writeTempFile(content: makeRunnableScript(script: script))
        
        let path = swiftFileURL!.absoluteString.replacingOccurrences(of: "file://", with: "")
        
       
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)
        let tempPath = temporaryDirectoryURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        

        let _ = try shellOut(to: "(cd \(tempPath) && swiftc \(path))")
        
        let runPath = path.replacingOccurrences(of: ".swift", with: "")
        
        let command = "(cd \(tempPath) && \(secretsCLI) \(runPath))"
        print("Command: \(command)")
        
        let output = try shellOut(to: command)
        
//        print("OUTPUT")
//        print(output)
        
        let data = output.data(using: .utf8)
        let decoder = JSONDecoder()

        let decodedOutput = try decoder.decode(Output.self, from: data!)

        return decodedOutput
    }
    

    private func makeRunnableScript(script: String) throws -> String {
        if let filepath = Bundle.main.path(forResource: "RunnerTemplate", ofType: "txt") {
            let contents = try String(contentsOfFile: filepath)
            
            return contents.replacingOccurrences(of: "REPLACE_HERE", with: script)
        } else {
            return ""
        }
    }
    
    private func createTempFilePath(ext: String = "") -> URL {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)

        let temporaryFilename = ProcessInfo().globallyUniqueString

        return temporaryDirectoryURL.appendingPathComponent("\(temporaryFilename)\(ext)")
    }
    
    private func writeTempFile(content: String) throws -> URL? {
        let temporaryFileURL = createTempFilePath(ext: ".swift")
        
        print("Writing file to \(temporaryFileURL)")
        if let data: Data = content.data(using: .utf8) {
            try data.write(to: temporaryFileURL,
                       options: .atomic)
            
            return temporaryFileURL
        }
        
        return nil
    }
}
