//
//  ViewController.swift
//  Build Settings
//
//  Created by Paulo F. Andrade on 07/02/2020.
//  Copyright © 2020 Paulo F. Andrade. All rights reserved.
//

import Cocoa

enum Errors: Error {
    case xcodeNotRunning
    case automationAuthorizationRequired
}

@objcMembers
class BuildSetting: NSObject {
    var name: String
    var value: String
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}


class ViewController: NSViewController {
    
    var projects: [XCDProject] = []
    
    @IBOutlet var selectionController: NSArrayController!
    @IBOutlet var settingsController: NSArrayController!
    var configurationPopUp: NSPopUpButton!
    
    var searchString: String? {
        didSet {
            guard let s = searchString, s.count > 0 else {
                settingsController.filterPredicate = nil
                return
            }
            settingsController.filterPredicate = NSPredicate(format: "name CONTAINS[c] %@ || value CONTAINS[c] %@", s,s)
        }
    }
    
    var windowController: WindowController? {
        return self.view.window?.windowController as? WindowController
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setupPopUp()
    }
    
    @objc func reload(_ sender: Any?) {
        windowController?.busy = true
        XcodeBridge.reloadBuildSettings { (results, error) in
            self.windowController?.busy = false
            guard let results = results else {
                NSAlert(error: error!).runModal()
                return
            }
            self.projects = results
            
            let configurations = results.flatMap { $0.targets }.flatMap { $0.configurations }
            self.selectionController.content = configurations.map { ItemWrapper(item: $0, includeProjects: results.count > 1) }
            
            if let selectedConfig = configurations.first {
                self.selectionController.setSelectionIndex(0)
                self.settingsController.content = selectedConfig.buildSettings.map { BuildSetting(name: $0.key, value: $0.value)
                }
            }
        }
    }
    
    @objc func copy(_ sender: Any?) {
        let text = self.settingsController.selectedObjects
            .compactMap { $0 as? BuildSetting }
            .reduce("") { (result, setting) -> String in
                return "\(result)\(setting.name) = \(setting.value)\n"
        }
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    // MARK: Configuration PopUp management
    func setupPopUp() {
        let toolbarPopUp = self.view.window?.toolbar?.items
            .filter { $0.itemIdentifier == .init(rawValue: "ConfigurationPopUp")}
            .first?.view as? NSPopUpButton
        guard let popUp = toolbarPopUp, let controller = selectionController else {
            return
        }
        
        popUp.bind(.content, to: controller, withKeyPath: "arrangedObjects", options: nil)
        popUp.bind(.contentValues, to: controller, withKeyPath: "arrangedObjects.path", options: nil)
        popUp.bind(.selectedIndex, to: controller, withKeyPath: "selectionIndex", options: nil)
        popUp.target = self
        popUp.action = #selector(popUpDidChange(_:))
    }
    
    @objc func popUpDidChange(_ sender: Any?) {
        guard let wrapper = selectionController.selectedObjects.first as? ItemWrapper,
            let selectedConfig = wrapper.item as? XCDConfiguration else {
            return
        }
        
        self.settingsController.content = selectedConfig.buildSettings.map { BuildSetting(name: $0.key, value: $0.value) }
    }
}


@objc class ItemWrapper: NSObject {
    var item: PopUpPathElement
    var includeProjects = true
    
    init(item: PopUpPathElement, includeProjects: Bool = true) {
        self.item = item
        self.includeProjects = includeProjects
    }
    
    @objc var path: String {
        var pathNames: [String] = []
        pathNames.append(item.name)
        var current = item
        while let el = current.parentElement {
            if el.isProject {
                if includeProjects {
                    pathNames.append(el.name)
                }
            }
            else {
                pathNames.append(el.name)
            }
            current = el
        }
        return pathNames.reversed().joined(separator: " > ")
    }
    
}

@objc protocol PopUpPathElement: NSObjectProtocol {
    @objc var isProject: Bool { get }
    @objc var parentElement: PopUpPathElement? { get }
    @objc var name: String { get }
}

extension XCDProject: PopUpPathElement {
    @objc var isProject: Bool {
        return true
    }
    @objc var parentElement: PopUpPathElement? {
        return nil
    }
}


extension XCDTarget: PopUpPathElement {
    @objc var isProject: Bool {
        return false
    }
    @objc var parentElement: PopUpPathElement? {
        return self.project
    }
}

extension XCDConfiguration: PopUpPathElement {
    @objc var isProject: Bool {
        return false
    }
    @objc var parentElement: PopUpPathElement? {
        return self.target
    }
}
