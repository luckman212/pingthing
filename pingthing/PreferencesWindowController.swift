//
//  PreferencesWindowController.swift
//
//  check: defaults read com.luckman212.pingthing
//  clear: defaults delete com.luckman212.pingthing

import AppKit
import ServiceManagement
import UserNotifications

// global prefs window / field dimensions
let w: CGFloat = 520
let h: CGFloat = 250
let lw: CGFloat = (w - 350)

class PasteableTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), let characters = event.charactersIgnoringModifiers {
            switch characters {
            case "v":
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
                return true
            case "x":
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
                return true
            case "a":
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
                return true
            case "z":
                NSApp.sendAction(Selector(("undo:")), to: nil, from: self)
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

class PreferencesWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    
    override func cancelOperation(_ sender: Any?) {
        if let controller = self.windowController as? PreferencesWindowController {
            controller.cancelClicked(sender)
        }
    }
}

class PreferencesWindowController: NSWindowController {
    var targetField = PasteableTextField()
    var intervalField = PasteableTextField()
    var timeoutField = PasteableTextField()
    var historySizeField = PasteableTextField()
    var barWidthField = PasteableTextField()
    
    let launchAtLoginToggle = NSSwitch(frame: .zero)

    var originalTarget: String = ""
    var originalInterval: String = ""
    var originalTimeout: String = ""
    var originalHistorySize: String = ""
    var originalBarWidth: String = ""
    
    init() {
        let window = PreferencesWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PingThing Settings"
        super.init(window: window)
        window.windowController = self
        setupUI()
        loadPreferences()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLabeledRow(
        labelText: String,
        textField: NSTextField,
        placeholder: String
    ) -> NSStackView {
        let label = NSTextField(labelWithString: labelText)
        label.font = .systemFont(ofSize: 14)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = .systemFont(ofSize: 14)
        textField.placeholderString = placeholder
        
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        
        // force label to a fixed width so fields line up
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: lw)
        ])
        
        row.addArrangedSubview(label)
        row.addArrangedSubview(textField)
        return row
    }
    
    private func createNarrowRowWithRightLabel(
        labelText: String,
        textField: NSTextField,
        placeholder: String,
        rightLabelText: String
    ) -> NSStackView {
        let label = NSTextField(labelWithString: labelText)
        label.font = .systemFont(ofSize: 14)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = .systemFont(ofSize: 14)
        textField.placeholderString = placeholder
        
        let rightLabel = NSTextField(labelWithString: rightLabelText)
        rightLabel.font = .systemFont(ofSize: 12)
        rightLabel.textColor = .secondaryLabelColor
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 8
        
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: lw),
            textField.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        row.addArrangedSubview(label)
        row.addArrangedSubview(textField)
        row.addArrangedSubview(rightLabel)
        return row
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let nf1 = NumberFormatter()
        nf1.minimum = 0.1
        nf1.maximum = 60
        nf1.allowsFloats = true
        nf1.numberStyle = .decimal

        let nf2 = NumberFormatter()
        nf2.minimum = 16
        nf2.maximum = 64
        nf2.allowsFloats = false
        nf2.numberStyle = .decimal
        
        let nf3 = NumberFormatter()
        nf3.minimum = 1
        nf3.maximum = 4
        nf3.allowsFloats = false
        nf3.numberStyle = .decimal
        
        intervalField.formatter = nf1
        timeoutField.formatter = nf1
        historySizeField.formatter = nf2
        barWidthField.formatter = nf3
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        mainStack.addArrangedSubview(
            createLabeledRow(
                labelText: "Target (hostname or IPv4)",
                textField: targetField,
                placeholder: defaultPingTarget
            )
        )
        mainStack.addArrangedSubview(
            createNarrowRowWithRightLabel(
                labelText: "Interval (sec)",
                textField: intervalField,
                placeholder: String(defaultPingInterval),
                rightLabelText: "(min 0.1, max 60)"
            )
        )
        mainStack.addArrangedSubview(
            createNarrowRowWithRightLabel(
                labelText: "Timeout (sec)",
                textField: timeoutField,
                placeholder: String(defaultPingTimeout),
                rightLabelText: "(min 0.1, max 60)"
            )
        )
        mainStack.addArrangedSubview(
            createNarrowRowWithRightLabel(
                labelText: "History size",
                textField: historySizeField,
                placeholder: String(defaultHistorySize),
                rightLabelText: "(min 16, max 64)"
            )
        )
        mainStack.addArrangedSubview(
            createNarrowRowWithRightLabel(
                labelText: "Bar width",
                textField: barWidthField,
                placeholder: String(defaultBarWidth),
                rightLabelText: "(min 1, max 4)"
            )
        )

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(separator)
        
        let bottomRow = NSStackView()
        bottomRow.orientation = .horizontal
        bottomRow.alignment = .centerY
        bottomRow.distribution = .fill
        bottomRow.spacing = 8
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        
        // LaunchAtLogin
        let launchAtLoginPref: Bool = getLoginItem().status == .enabled
        launchAtLoginToggle.state = (launchAtLoginPref == true ? .on : .off)
        launchAtLoginToggle.target = self
        launchAtLoginToggle.action = #selector(toggleChanged(_:))
        let launchAtLoginLabel = NSTextField(labelWithString: "Launch at login")
        launchAtLoginLabel.font = .systemFont(ofSize: 14)
        launchAtLoginLabel.translatesAutoresizingMaskIntoConstraints = false
        let launchAtLoginStack = NSStackView(views: [launchAtLoginToggle, launchAtLoginLabel])
        launchAtLoginStack.orientation = .horizontal
        launchAtLoginStack.alignment = .centerY
        launchAtLoginStack.spacing = 6

        let flexibleSpace = NSView()
        flexibleSpace.translatesAutoresizingMaskIntoConstraints = false

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 0
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.controlSize = .regular
        cancelButton.font = NSFont.systemFont(ofSize: 14)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.controlSize = .regular
        saveButton.font = NSFont.systemFont(ofSize: 14)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 90),
            cancelButton.heightAnchor.constraint(equalToConstant: 34),
            saveButton.widthAnchor.constraint(equalToConstant: 90),
            saveButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        let buttonStack = NSStackView(views: [cancelButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 10
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonContainer = NSView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(buttonStack)
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor)
        ])
        
        bottomRow.addArrangedSubview(launchAtLoginStack)
        bottomRow.addArrangedSubview(flexibleSpace)
        bottomRow.addArrangedSubview(buttonStack)
        mainStack.addArrangedSubview(bottomRow)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    private func loadPreferences() {
        let target = UserDefaults.standard.object(forKey: "PingTarget") as? String ?? defaultPingTarget
        let interval = UserDefaults.standard.object(forKey: "PingInterval") as? Double ?? defaultPingInterval
        let timeout = UserDefaults.standard.object(forKey: "PingTimeout") as? Double ?? defaultPingTimeout
        let historySize = UserDefaults.standard.object(forKey: "HistorySize") as? Int ?? defaultHistorySize
        let barWidth = UserDefaults.standard.object(forKey: "BarWidth") as? Int ?? defaultBarWidth
        
        targetField.stringValue = target
        intervalField.stringValue = String(interval)
        timeoutField.stringValue = String(timeout)
        historySizeField.stringValue = String(historySize)
        barWidthField.stringValue = String(barWidth)

        originalTarget = targetField.stringValue
        originalInterval = intervalField.stringValue
        originalTimeout = timeoutField.stringValue
        originalHistorySize = historySizeField.stringValue
        originalBarWidth = barWidthField.stringValue
    }
    
    @objc func saveClicked(_ sender: Any) {
        UserDefaults.standard.set (targetField.stringValue == "" ? defaultPingTarget : targetField.stringValue, forKey: "PingTarget")
        UserDefaults.standard.set(Double(intervalField.stringValue) ?? defaultPingInterval, forKey: "PingInterval")
        UserDefaults.standard.set(Double(timeoutField.stringValue) ?? defaultPingTimeout, forKey: "PingTimeout")
        UserDefaults.standard.set(Int(historySizeField.stringValue) ?? defaultHistorySize, forKey: "HistorySize")
        UserDefaults.standard.set(Int(barWidthField.stringValue) ?? defaultBarWidth, forKey: "BarWidth")
        window?.close()
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
    }
    
    @objc func cancelClicked(_ sender: Any?) {
        targetField.stringValue = originalTarget
        intervalField.stringValue = originalInterval
        timeoutField.stringValue = originalTimeout
        historySizeField.stringValue = originalHistorySize
        barWidthField.stringValue = originalBarWidth
        window?.close()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        loadPreferences()
        if let screen = NSScreen.main, let win = self.window {
            let screenFrame = screen.visibleFrame
            let newX = (screenFrame.width - win.frame.width) / 2
            let newY = (screenFrame.height - win.frame.height) / 2
            win.setFrameOrigin(NSPoint(x: newX, y: newY + (screenFrame.height * 0.15)))
        }
        window?.makeFirstResponder(targetField)
    }
    
    @objc func toggleChanged(_ sender: NSSwitch) {
        let enabled = sender.state == .on
        print("DEBUG: in toggleChanged(): LaunchAtLogin=\(enabled == true ? "On" : "Off")")
        setLaunchAtLogin(enabled)
    }
    
    private func getLoginItem() -> SMAppService {
        /* possible values of .status:
            .enabled → currently registered
            .notRegistered → never registered
            .requiresApproval → user hasn’t approved it yet (e.g., MDM policy)
            .notFound → bundle ID isn’t valid or not embedded properly
        */
        let service = SMAppService.loginItem(identifier: "com.luckman212.pingthing.LoginHelper")
        return service
    }
    
    private func setLaunchAtLogin(_ enable: Bool) {
        print("DEBUG: in setLaunchAtLogin()")
        do {
            let helper = getLoginItem()
            if enable {
                try helper.register()
                print("DEBUG: register() LaunchAtLogin=On")
                //showNotification(title: k_AppName, body: "Launch at login has been enabled.")
            } else {
                try helper.unregister()
                print("DEBUG: unregister() LaunchAtLogin=Off")
                //showNotification(title: k_AppName, body: "Launch at login has been disabled.")
            }
        } catch {
            print("Failed to update login item: \(error)")
            showNotification(title: k_AppName, body: "Error: \(error)")
        }
    }

}
