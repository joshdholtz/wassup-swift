//
//  main.swift
//  Wassup
//
//  Created by Josh Holtz on 3/16/22.
//

import AppKit

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
