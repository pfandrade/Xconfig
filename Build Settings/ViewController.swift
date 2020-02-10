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
    
    override func viewDidAppear() {
        super.viewDidAppear()
        reload(self)
    }
    
    @objc func reload(_ sender: Any?) {
        windowController?.busy = true
        XcodeBridge.reloadAvailableTargets { (results, error) in
            self.windowController?.busy = false
            guard let results = results else {
                NSAlert(error: error!).runModal()
                return
            }
            
            let targets = results.flatMap { $0.targets }
            self.targetSelectionController.content = targets.map { ItemWrapper(item: $0, includeProjects: results.count > 1) }
            
            if let target = targets.first {
                self.selectedTarget = target
                self.targetSelectionController.setSelectionIndex(0)
                
            }
        }
    }
    
    // MARK: Actions
    @objc func copy(_ sender: Any?) {
        let text = self.settingsController.selectedObjects
            .compactMap { $0 as? BuildSetting }
            .reduce("") { (result, setting) -> String in
                return "\(result)\(setting.name) = \(setting.value)\n"
        }
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    // MARK: Target selection
    
    @IBOutlet var targetSelectionController: NSArrayController!
    func setupPopUp() {
        let toolbarPopUp = self.view.window?.toolbar?.items
            .filter { $0.itemIdentifier == .init(rawValue: "ConfigurationPopUp")}
            .first?.view as? NSPopUpButton
        guard let popUp = toolbarPopUp, let controller = targetSelectionController else {
            return
        }
        
        popUp.bind(.content, to: controller, withKeyPath: "arrangedObjects", options: nil)
        popUp.bind(.contentValues, to: controller, withKeyPath: "arrangedObjects.path", options: nil)
        popUp.bind(.selectedIndex, to: controller, withKeyPath: "selectionIndex", options: nil)
        popUp.target = self
        popUp.action = #selector(popUpDidChange(_:))
    }
    
    @objc func popUpDidChange(_ sender: Any?) {
        guard let wrapper = targetSelectionController.selectedObjects.first as? ItemWrapper else {
            return
        }
        selectedTarget = wrapper.item as? XCDTarget
    }
    
    var selectedTarget: XCDTarget? {
        didSet {
            self.configurationsController.content = selectedTarget?.configurations ?? []
            self.selectedConfiguration = (self.configurationsController.selectedObjects.first as? ItemWrapper)?.item as? XCDConfiguration
            if let target = selectedTarget, target.configurations == nil {
                target.updateConfigurations { (configs) in
                    if target == self.selectedTarget {
                        self.configurationsController.content = configs.map { ItemWrapper(item: $0, includeProjects: false) }
                        self.selectedConfiguration = (self.configurationsController.selectedObjects.first as? ItemWrapper)?.item as? XCDConfiguration
                    }
                }
            }
        }
    }
    
    // MARK: Configuration selection
    @IBOutlet var configurationsController: NSArrayController!
    var selectedConfiguration: XCDConfiguration? {
        didSet {
            settingsController.content = (selectedConfiguration?.buildSettings ?? [:]).map { BuildSetting(name: $0.key, value: $0.value) }
            if let config = selectedConfiguration, config.buildSettings == nil {
                config.updateBuildSettings { (settings) in
                    if config == self.selectedConfiguration {
                        self.settingsController.content = settings.map { BuildSetting(name: $0.key, value: $0.value) }
                    }
                }
            }
        }
    }
        
    @IBAction func configurationSelectionDidChange(_ sender: Any) {
        guard let wrapper = configurationsController.selectedObjects.first as? ItemWrapper else {
            return
        }
        selectedConfiguration = wrapper.item as? XCDConfiguration
    }
   
    // MARK: Build Settings
    @IBOutlet var settingsController: NSArrayController!
    
    
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
    
    override var description: String {
        return self.item.name
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
