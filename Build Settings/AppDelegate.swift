//
//  AppDelegate.swift
//  Build Settings
//
//  Created by Paulo F. Andrade on 07/02/2020.
//  Copyright © 2020 Outer Corner. All rights reserved.
//

import Cocoa

enum StateRestorationErrors: Error {
    case unknownWindowIdentifier
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowRestoration {
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if windowControllers.count == 0 {
            newWindow(nil)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    // MARK: Window handling
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        if identifier.rawValue.hasPrefix("Main") {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            completionHandler(appDelegate.newWindowController().window, nil)
        }
        else {
            completionHandler(nil, StateRestorationErrors.unknownWindowIdentifier)
        }
    }
    
    var windowControllers: [WindowController] = []
    
    func newWindowController() -> WindowController {
        let wc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("MainWindowController")) as! WindowController
        windowControllers.append(wc)
        
        var observer: Any? = nil
        observer = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: wc.window, queue: .main) { [unowned wc] (note) in
            guard let observer = observer else {
                return
            }
            NotificationCenter.default.removeObserver(observer)
            self.windowControllers.removeAll(where: { $0 == wc })
        }
        return wc
    }
    
    @IBAction func newWindow(_ sender: Any?) {
        let lastWindow = windowControllers.last?.window
        
        let wc = newWindowController()
        guard let window = wc.window else {
            return
        }
        window.isRestorable = true
        window.identifier = NSUserInterfaceItemIdentifier(rawValue: "Main \(UUID().uuidString)")
        window.restorationClass = Self.self
        wc.showWindow(sender)
        
        if let lastWindow = lastWindow {
            let topLeftX = lastWindow.frame.origin.x
            let topLeftY = lastWindow.frame.maxY
            let newTopLeft = lastWindow.cascadeTopLeft(from: CGPoint(x: topLeftX, y: topLeftY))
            window.setFrameTopLeftPoint(newTopLeft)
        }
    }
}

