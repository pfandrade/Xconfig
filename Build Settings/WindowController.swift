//
//  WindowController.swift
//  Build Settings
//
//  Created by Paulo F. Andrade on 08/02/2020.
//  Copyright © 2020 Paulo F. Andrade. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSTextFieldDelegate {    
    

    var viewController: ViewController? {
        return self.window?.contentViewController as? ViewController
    }
    

    @IBOutlet weak var searchField: NSSearchField!
    func controlTextDidChange(_ obj: Notification) {
        viewController?.searchString = searchField.stringValue
    }

    
    @objc dynamic var busy: Bool = false
}
