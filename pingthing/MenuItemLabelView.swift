//
//  MenuItemLabelView.swift
//

import AppKit

class MenuItemLabelView: NSView {
    let label: NSTextField

    init(text: String, color: NSColor, frame: NSRect = .zero) {
        label = NSTextField(labelWithString: text)
        label.font = NSFont.menuFont(ofSize: NSFont.systemFontSize)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBordered = false
        label.alignment = .left

        let initialFrame = frame.equalTo(.zero) ? NSRect(origin: .zero, size: NSSize(width: 200, height: 22)) : frame
        super.init(frame: initialFrame)
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let labelSize = label.intrinsicContentSize
        return NSSize(width: labelSize.width + 40, height: max(labelSize.height, 22))
    }

    func updateText(_ newText: String) {
        label.stringValue = newText
        self.frame = NSRect(origin: self.frame.origin, size: self.intrinsicContentSize)
        invalidateIntrinsicContentSize()
    }

    func updateColor(_ newColor: NSColor) {
        label.textColor = newColor
    }
}
