//
//  WindowController.swift
//  Build Settings
//
//  Created by Paulo F. Andrade on 08/02/2020.
//  Copyright © 2020 Outer Corner. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSTextFieldDelegate {

    deinit {
        NSLog("Close")
    }
    
    
    var viewController: ViewController? {
        return self.window?.contentViewController as? ViewController
    }
    

    @IBOutlet weak var searchField: NSSearchField!
    func controlTextDidChange(_ obj: Notification) {
        viewController?.searchString = searchField.stringValue
    }
    

}
