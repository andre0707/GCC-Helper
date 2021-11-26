//
//  AppDelegate.swift
//  GCC-Helper
//
//  Created by Andre Albach on 24.11.21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
    // MARK: - Menu interactions
    
    /// Called when the menu item `Open Readme` is clicked
    /// - Parameter sender: The menu item which was clicked
    @IBAction func menuOpenReadme(_ sender: NSMenuItem) {
        guard let mainVC = NSApplication.shared.mainWindow?.windowController?.contentViewController as? MainVC else { return }
        
        mainVC.openReadme()
    }
}
