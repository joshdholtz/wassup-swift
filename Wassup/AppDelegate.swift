//
//  AppDelegate.swift
//  Wassup
//
//  Created by Josh Holtz on 3/16/22.
//

import Cocoa
import SwiftUI

struct StatusItemView: View {
    
    let counts: [Output.Pane.CountAlert: Int]
    
    var imageName: String {
        if (counts[.high] ?? 0) > 0 {
            return "xmark.seal"
        } else if (counts[.medium] ?? 0) > 0 {
            return "seal"
        } else if (counts[.low] ?? 0) > 0 {
            return "seal"
        }
        
        return "seal"
    }
    
    var count: Int {
        if (counts[.high] ?? 0) > 0 {
            return counts[.high] ?? 0
        } else if (counts[.medium] ?? 0) > 0 {
            return counts[.medium] ?? 0
        } else if (counts[.low] ?? 0) > 0 {
            return counts[.low] ?? 0
        }
        
        return 0
    }
    
    var color: Color? {
        if (counts[.high] ?? 0) > 0 {
            return Color.red
        } else if (counts[.medium] ?? 0) > 0 {
            return Color.orange
        } else if (counts[.low] ?? 0) > 0 {
            return Color.yellow
        }
        
        return nil
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(String(count))")
                .foregroundColor(color)
            Image(systemName: imageName)
        }.padding(.horizontal, 5)
    }
}

//@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItemHost: NSHostingView<StatusItemView>!
    private var statusItem: NSStatusItem!
    
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = ContentView()
        
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        
        let controller = NSHostingController(rootView: contentView)
        controller.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        popover.contentViewController = controller
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//
//        let view = NSHostingView(rootView: ContentView())
//        view.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
//
//        let menuItem = NSMenuItem()
//        menuItem.view = view
//
//        let menu = NSMenu()
//        menu.addItem(menuItem)
//
//        statusItem.menu = menu
//
        if let button = statusItem.button {
//            button.image = NSImage(systemSymbolName: "seal", accessibilityDescription: "1")
            
            let statusItemView = StatusItemView(counts: [:])
            
            statusItemHost = NSHostingView(rootView: statusItemView)
            statusItemHost.frame = NSRect(x: 0, y: 0, width: 60, height: 22)
            statusItemHost.wantsLayer = true
            
            button.frame = statusItemHost.frame
            button.addSubview(statusItemHost)
            button.action = #selector(menuToggle)
            
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAlertCount(_:)), name: .wassupNewData, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(handle), name: .wassupResetData, object: nil)
    }
    
    @objc func handleAlertCount(_ notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            let counts = notification.userInfo as? [Output.Pane.CountAlert: Int] ?? [:]
 
            let statusItemView = StatusItemView(counts: counts)
            statusItemHost.rootView = statusItemView
        }
    }
    
    @objc func menuToggle() {
        if let menuButton = statusItem.button {
            self.popover.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: .minY)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Wassup")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

extension AppDelegate: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverDidShow(_ notification: Notification) {
        NotificationCenter.default.post(name: .popoverDidShow, object: nil)
    }
}

extension Notification.Name {
    static let popoverDidShow = Notification.Name("popoverDidShow")
    
    static let wassupNewData = Notification.Name("wassupNewData")
    static let wassupResetData = Notification.Name("wassupResetData")
}

extension NSImage {
   func image(withTintColor tintColor: NSColor) -> NSImage {
       guard isTemplate else { return self }
       guard let copiedImage = self.copy() as? NSImage else { return self }
       copiedImage.lockFocus()
       tintColor.set()
       let imageBounds = NSMakeRect(0, 0, copiedImage.size.width, copiedImage.size.height)
       imageBounds.fill(using: .sourceAtop)
       copiedImage.unlockFocus()
       copiedImage.isTemplate = false
       return copiedImage
   }
}
