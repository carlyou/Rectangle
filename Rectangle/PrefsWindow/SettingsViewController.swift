//
//  SettingsViewController.swift
//  Rectangle
//
//  Created by Ryan Hanson on 8/24/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa
import ServiceManagement
import Sparkle
import MASShortcut

class SettingsViewController: NSViewController {
        
    @IBOutlet weak var launchOnLoginCheckbox: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var hideMenuBarIconCheckbox: NSButton!
    @IBOutlet weak var subsequentExecutionPopUpButton: NSPopUpButton!
    @IBOutlet weak var allowAnyShortcutCheckbox: NSButton!
    @IBOutlet weak var checkForUpdatesAutomaticallyCheckbox: NSButton!
    @IBOutlet weak var checkForUpdatesButton: NSButton!
    @IBOutlet weak var gapSlider: NSSlider!
    @IBOutlet weak var gapLabel: NSTextField!
    @IBOutlet weak var cursorAcrossCheckbox: NSButton!
    @IBOutlet weak var doubleClickTitleBarCheckbox: NSButton!
    @IBOutlet weak var todoCheckbox: NSButton!
    @IBOutlet weak var todoView: NSStackView!
    @IBOutlet weak var todoAppWidthField: AutoSaveFloatField!
    @IBOutlet weak var todoAppSidePopUpButton: NSPopUpButton!
    @IBOutlet weak var toggleTodoShortcutView: MASShortcutView!
    @IBOutlet weak var reflowTodoShortcutView: MASShortcutView!
    @IBOutlet weak var stageView: NSStackView!
    @IBOutlet weak var stageSlider: NSSlider!
    @IBOutlet weak var stageLabel: NSTextField!
    private var movementSlider: NSControl!
    private var movementLabel: NSTextField!
    private var movementStackView: NSStackView?
    
    @IBOutlet var todoViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var actionSpecificCycleSizesView: NSStackView!
    @IBOutlet var actionSpecificCycleSizesViewHeightConstraint: NSLayoutConstraint!
    
    
    private var aboutTodoWindowController: NSWindowController?
    private var cycleSizeWindowController: NSWindowController?
    
    @IBAction func toggleLaunchOnLogin(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        if #available(macOS 13, *) {
            LaunchOnLogin.isEnabled = newSetting
        } else {
            let smLoginSuccess = SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
            if !smLoginSuccess {
                Logger.log("Unable to set launch at login preference. Attempting one more time.")
                SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
            }            
        }
        Defaults.launchOnLogin.enabled = newSetting
    }
    
    @IBAction func toggleHideMenuBarIcon(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.hideMenuBarIcon.enabled = newSetting
        RectangleStatusItem.instance.refreshVisibility()
    }

    @IBAction func setSubsequentExecutionBehavior(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        guard let mode = SubsequentExecutionMode(rawValue: tag) else {
            Logger.log("Expected a pop up button to have a selected item with a valid tag matching a value of SubsequentExecutionMode. Got: \(String(describing: tag))")
            return
        }

        Defaults.subsequentExecutionMode.value = mode
        showHideActionSpecificCycleSizesButton(animated: true)
    }
    
    @IBAction func gapSliderChanged(_ sender: NSSlider) {
        gapLabel.stringValue = "\(sender.intValue) px"
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                if Float(sender.intValue) != Defaults.gapSize.value {
                    Defaults.gapSize.value = Float(sender.intValue)
                }
            }
        }
    }
    
    @IBAction func toggleCursorMove(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.moveCursorAcrossDisplays.enabled = newSetting
    }
    
    @IBAction func toggleAllowAnyShortcut(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.allowAnyShortcut.enabled = newSetting
        Notification.Name.allowAnyShortcut.post(object: newSetting)
    }
    
    @IBAction func checkForUpdates(_ sender: Any) {
        AppDelegate.updaterController.checkForUpdates(sender)
    }
    
    @IBAction func toggleDoubleClickTitleBar(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        if newSetting && !TitleBarManager.systemSettingDisabled {
            
            var openSystemSettingsButtonName = NSLocalizedString("iWV-c2-BJD.title", tableName: "Main", value: "Open System Preferences", comment: "")
            
            if #available(macOS 13, *) {
                openSystemSettingsButtonName = NSLocalizedString(
                    "Open System Settings", tableName: "Main", value: "", comment: "")
            }

            let conflictTitleText = NSLocalizedString(
                "Conflict with system setting", tableName: "Main", value: "", comment: "")
            let conflictDescriptionText = NSLocalizedString(
                "To let Rectangle manage the title bar double click functionality, you need to disable the corresponding macOS setting.", tableName: "Main", value: "", comment: "")

            
            let closeText = NSLocalizedString("DVo-aG-piG.title", tableName: "Main", value: "Close", comment: "")
            
            let response = AlertUtil.twoButtonAlert(question: conflictTitleText, text: conflictDescriptionText, confirmText: openSystemSettingsButtonName, cancelText: closeText)
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.dock")!)
            }
        }
        Defaults.doubleClickTitleBar.value = (newSetting ? WindowAction.maximize.rawValue : -1) + 1
        Notification.Name.windowTitleBar.post()
    }
    
    @IBAction func toggleTodoMode(_ sender: NSButton) {
        let newSetting: Bool = sender.state == .on
        Defaults.todo.enabled = newSetting
        showHideTodoModeSettings(animated: true)
        Notification.Name.todoMenuToggled.post()
    }
    
    @IBAction func showTodoModeHelp(_ sender: Any) {
        if aboutTodoWindowController == nil {
            aboutTodoWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "AboutTodoWindowController") as? NSWindowController
        }
        NSApp.activate(ignoringOtherApps: true)
        aboutTodoWindowController?.showWindow(self)
    }
    
    @IBAction func setTodoAppSide(_ sender: NSPopUpButton) {
        let tag = sender.selectedTag()
        guard let side = TodoSidebarSide(rawValue: tag) else {
            Logger.log("Expected a pop up button to have a selected item with a valid tag matching a value of TodoSidebarSide. Got: \(String(describing: tag))")
            return
        }

        Defaults.todoSidebarSide.value = side
        
        TodoManager.moveAllIfNeeded(false)
    }
    
    @IBAction func stageSliderChanged(_ sender: NSSlider) {
        stageLabel.stringValue = "\(sender.intValue) px"
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                let value: Float = sender.floatValue == 0 ? -1 : sender.floatValue
                if value != Defaults.stageSize.value {
                    Defaults.stageSize.value = value
                }
            }
        }
    }
    
    @IBAction func movementTextChanged(_ sender: NSTextField) {
        if let value = parseOffsetValue(sender.stringValue) {
            Defaults.pureMovementOffset.value = value
            sender.stringValue = formatOffsetValue(value) // Normalize the display
        }
    }
    
    private func parseOffsetValue(_ input: String) -> Float? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // Handle percentage (e.g., "8%")
        if trimmed.hasSuffix("%") {
            let numberPart = String(trimmed.dropLast())
            if let percentage = Float(numberPart) {
                return percentage / 100.0
            }
        }
        
        // Handle fractions (e.g., "1/12", "1/3")
        if trimmed.contains("/") {
            let parts = trimmed.components(separatedBy: "/")
            if parts.count == 2,
               let numerator = Float(parts[0].trimmingCharacters(in: .whitespaces)),
               let denominator = Float(parts[1].trimmingCharacters(in: .whitespaces)),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Handle decimal (e.g., "0.083")
        if let decimal = Float(trimmed) {
            return decimal
        }
        
        return nil
    }
    
    private func formatOffsetValue(_ value: Float) -> String {
        // Try to represent as a nice fraction first
        let commonFractions: [(Float, String)] = [
            (1.0/12.0, "1/12"),
            (1.0/6.0, "1/6"),
            (1.0/4.0, "1/4"),
            (1.0/3.0, "1/3"),
            (1.0/2.0, "1/2")
        ]
        
        for (fraction, display) in commonFractions {
            if abs(value - fraction) < 0.001 {
                return display
            }
        }
        
        // Otherwise show as percentage if it's a nice round number
        let percentage = value * 100
        if percentage == round(percentage) {
            return "\(Int(percentage))%"
        }
        
        // Finally, show as decimal
        return String(format: "%.3f", value)
    }
    
    @IBAction func restoreDefaults(_ sender: Any) {
        // Ask user if they want to restore to Rectangle or Spectacle defaults
        let currentDefaults = Defaults.alternateDefaultShortcuts.enabled ? "Rectangle" : "Spectacle"
        let defaultShortcutsTitle = NSLocalizedString("Default Shortcuts", tableName: "Main", value: "", comment: "")
        let currentlyUsingText = NSLocalizedString("Currently using: ", tableName: "Main", value: "", comment: "")
        let cancelText = NSLocalizedString("Cancel", tableName: "Main", value: "", comment: "")
        let response = AlertUtil.threeButtonAlert(question: defaultShortcutsTitle, text: currentlyUsingText + currentDefaults, buttonOneText: "Rectangle", buttonTwoText: "Spectacle", buttonThreeText: cancelText)
        if response == .alertThirdButtonReturn { return }

        //  Restore default shortcuts
        WindowAction.active.forEach { UserDefaults.standard.removeObject(forKey: $0.name) }
        let rectangleDefaults = response == .alertFirstButtonReturn
        if rectangleDefaults != Defaults.alternateDefaultShortcuts.enabled {
            Defaults.alternateDefaultShortcuts.enabled = rectangleDefaults
            Notification.Name.changeDefaults.post()
        }
        
        // Restore snap areas
        Defaults.portraitSnapAreas.typedValue = nil
        Defaults.landscapeSnapAreas.typedValue = nil
        Notification.Name.defaultSnapAreas.post()
    }
    
    @IBAction func exportConfig(_ sender: NSButton) {
        Notification.Name.windowSnapping.post(object: false)
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "RectangleConfig"
        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                if let jsonString = Defaults.encoded() {
                    try jsonString.write(to: url, atomically: false, encoding: .utf8)
                }
            }
            catch {
                Logger.log(error.localizedDescription)
            }
        }
        Notification.Name.windowSnapping.post(object: true)
    }
    
    @IBAction func importConfig(_ sender: NSButton) {
        Notification.Name.windowSnapping.post(object: false)
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]
        let response = openPanel.runModal()
        if response == .OK, let url = openPanel.url {
            Defaults.load(fileUrl: url)
        }
        Notification.Name.windowSnapping.post(object: true)
    }
    
    override func awakeFromNib() {
        initializeToggles()

        checkForUpdatesAutomaticallyCheckbox.bind(.value, to: AppDelegate.updaterController.updater, withKeyPath: "automaticallyChecksForUpdates", options: nil)
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        versionLabel.stringValue = "v" + appVersionString + " (" + buildString + ")"

        checkForUpdatesButton.title = NSLocalizedString("HIK-3r-i7E.title", tableName: "Main", value: "Check for Updates…", comment: "")
        
        initializeTodoModeSettings()
        
        showHideActionSpecificCycleSizesButton(animated: false)
        
        setupMovementControls()
        
        Notification.Name.configImported.onPost(using: {_ in
            self.initializeTodoModeSettings()
            self.initializeToggles()
            self.showHideActionSpecificCycleSizesButton(animated: false)
        })
        
        Notification.Name.menuBarIconHidden.onPost(using: {_ in
            self.hideMenuBarIconCheckbox.state = .on
        })
    }
    
    func initializeTodoModeSettings() {
        todoCheckbox.state = Defaults.todo.userEnabled ? .on : .off
        todoAppWidthField.stringValue = String(Defaults.todoSidebarWidth.value)
        todoAppWidthField.delegate = self
        todoAppWidthField.defaults = Defaults.todoSidebarWidth
        todoAppWidthField.defaultsSetAction = {
            TodoManager.moveAllIfNeeded(false)
        }
        todoAppSidePopUpButton.selectItem(withTag: Defaults.todoSidebarSide.value.rawValue)
        TodoManager.initToggleShortcut()
        TodoManager.initReflowShortcut()
        toggleTodoShortcutView.setAssociatedUserDefaultsKey(TodoManager.toggleDefaultsKey, withTransformerName: MASDictionaryTransformerName)
        reflowTodoShortcutView.setAssociatedUserDefaultsKey(TodoManager.reflowDefaultsKey, withTransformerName: MASDictionaryTransformerName)
        showHideTodoModeSettings(animated: false)
    }
    
    private func showHideTodoModeSettings(animated: Bool) {
        animateChanges(animated: animated) {
            let isEnabled = Defaults.todo.userEnabled
            todoView.isHidden = !isEnabled
            todoViewHeightConstraint.isActive = !isEnabled
        }
    }
    
    func initializeToggles() {
        checkForUpdatesAutomaticallyCheckbox.state = Defaults.SUEnableAutomaticChecks.enabled ? .on : .off
        
        launchOnLoginCheckbox.state = Defaults.launchOnLogin.enabled ? .on : .off
        
        hideMenuBarIconCheckbox.state = Defaults.hideMenuBarIcon.enabled ? .on : .off
        
        subsequentExecutionPopUpButton.selectItem(withTag: Defaults.subsequentExecutionMode.value.rawValue)
        
        allowAnyShortcutCheckbox.state = Defaults.allowAnyShortcut.enabled ? .on : .off
                
        gapSlider.intValue = Int32(Defaults.gapSize.value)
        gapLabel.stringValue = "\(gapSlider.intValue) px"
        gapSlider.isContinuous = true
        
        cursorAcrossCheckbox.state = Defaults.moveCursorAcrossDisplays.userEnabled ? .on : .off
        
        doubleClickTitleBarCheckbox.state = WindowAction(rawValue: Defaults.doubleClickTitleBar.value - 1) != nil ? .on : .off

        if StageUtil.stageCapable {
            stageSlider.intValue = Int32(Defaults.stageSize.value)
            stageSlider.isContinuous = true
            stageLabel.stringValue = "\(stageSlider.intValue) px"
        } else {
            stageView.isHidden = true
        }
        
        if let textField = movementSlider as? NSTextField, let label = movementLabel {
            textField.stringValue = formatOffsetValue(Defaults.pureMovementOffset.value)
        }
    }
    
    private func setupMovementControls() {
        // Check if already set up to prevent duplicates
        if movementStackView != nil {
            return
        }
        
        // Find the main stack view to add our controls to
        guard let mainStackView = view.subviews.first(where: { $0 is NSStackView }) as? NSStackView else {
            return
        }
        
        // Create horizontal stack view for movement controls
        let movementStack = NSStackView()
        movementStack.orientation = .horizontal
        movementStack.alignment = .centerY
        movementStack.spacing = 10
        movementStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create label
        let titleLabel = NSTextField(labelWithString: "Movement Step Size:")
        titleLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        titleLabel.alignment = .right
        titleLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .horizontal)
        
        // Create text input field
        movementSlider = NSTextField() // Reusing the same variable name for simplicity
        if let textField = movementSlider as? NSTextField {
            textField.stringValue = formatOffsetValue(Defaults.pureMovementOffset.value)
            textField.target = self
            textField.action = #selector(movementTextChanged(_:))
            textField.delegate = self
            textField.placeholderString = "e.g., 1/12, 0.083, 8%"
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.widthAnchor.constraint(equalToConstant: 160).isActive = true
            textField.heightAnchor.constraint(equalToConstant: 21).isActive = true
        }
        
        // Create info label  
        movementLabel = NSTextField(labelWithString: "of screen")
        movementLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        movementLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .horizontal)
        movementLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .horizontal)
        
        // Add to stack
        movementStack.addArrangedSubview(titleLabel)
        movementStack.addArrangedSubview(movementSlider)
        movementStack.addArrangedSubview(movementLabel)
        
        // Width constraint is already set in the text field creation
        
        // Insert after the gap slider (try to find it in the stack)
        var insertIndex = 0
        for (index, subview) in mainStackView.arrangedSubviews.enumerated() {
            if let stackView = subview as? NSStackView,
               stackView.arrangedSubviews.contains(where: { $0 is NSSlider }) {
                insertIndex = index + 1
                break
            }
        }
        
        mainStackView.insertArrangedSubview(movementStack, at: insertIndex)
        movementStackView = movementStack
    }

    private func animateChanges(animated: Bool, block: () -> Void) {
        if animated {
            NSAnimationContext.runAnimationGroup({context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                
                block()
                view.layoutSubtreeIfNeeded()
            }, completionHandler: nil)
        } else {
            block()
        }
    }
    
    private func showHideActionSpecificCycleSizesButton(animated: Bool = false) {
        let showOptionsView = Defaults.subsequentExecutionMode.resizes
        
        if showOptionsView {
            addConfigureActionCycleSizesButton()
        } else {
            removeConfigureActionCycleSizesButton()
        }
        
        animateChanges(animated: animated) {
            actionSpecificCycleSizesView.isHidden = !showOptionsView
            actionSpecificCycleSizesViewHeightConstraint.isActive = !showOptionsView
        }
    }
    
    private func removeConfigureActionCycleSizesButton() {
        for subview in actionSpecificCycleSizesView.arrangedSubviews {
            if let button = subview as? NSButton, button.title == "Configure Action-Specific Cycle Sizes..." {
                actionSpecificCycleSizesView.removeArrangedSubview(button)
                button.removeFromSuperview()
                return
            }
        }
    }
    
    private func addConfigureActionCycleSizesButton() {
        // Check if button already exists to avoid duplicates
        for subview in actionSpecificCycleSizesView.arrangedSubviews {
            if let button = subview as? NSButton, button.title == "Configure Action-Specific Cycle Sizes..." {
                return
            }
        }
        
        let button = NSButton(title: "Configure Action-Specific Cycle Sizes...", target: self, action: #selector(openActionCycleSizesWindow))
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        button.setContentHuggingPriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        button.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(1000), for: .vertical)
        actionSpecificCycleSizesView.addArrangedSubview(button)
    }
    
    @objc private func openActionCycleSizesWindow() {
        if cycleSizeWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateController(withIdentifier: "CycleSizeViewController") as! CycleSizeViewController
            let window = NSWindow(contentViewController: viewController)
            window.title = "Action-Specific Cycle Sizes"
            
            // Make it larger and resizable for better usability
            window.setContentSize(NSSize(width: 600, height: 500))
            window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable, NSWindow.StyleMask.resizable]
            window.minSize = NSSize(width: 500, height: 400)
            window.center()
            
            cycleSizeWindowController = NSWindowController(window: window)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        cycleSizeWindowController?.showWindow(self)
    }

}

extension SettingsViewController {
    static func freshController() -> SettingsViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = "SettingsViewController"
        guard let viewController = storyboard.instantiateController(withIdentifier: identifier) as? SettingsViewController else {
            fatalError("Unable to find ViewController - Check Main.storyboard")
        }
        return viewController
    }
}

extension SettingsViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let sender = obj.object as? AutoSaveFloatField,
              let defaults: FloatDefault = sender.defaults else { return }
        
        Debounce<Float>.input(sender.floatValue, comparedAgainst: sender.floatValue) { floatValue in
            defaults.value = floatValue
            sender.defaultsSetAction?()
        }
    }
}

class AutoSaveFloatField: NSTextField {
    var defaults: FloatDefault?
    var defaultsSetAction: (() -> Void)?
}
