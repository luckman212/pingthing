//
//  LogWindowController.swift
//

import Cocoa

class DebugLogger {
    static let shared = DebugLogger()
    private var messages: [String] = []
    private let queue = DispatchQueue(label: k_logwindow_q)

    private init() {}
    
    func log(_ message: String) {
        queue.async {
            self.messages.append(message)
            
            if isatty(STDOUT_FILENO) != 0 {
                print(message)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .printDebugMessage, object: message)
            }
        }
    }
    
    func fullLog() -> String {
        return queue.sync {
            self.messages.joined(separator: "\n")
        }
    }
}

class LogWindowController: NSWindowController {
    let textView: NSTextView

    init() {
        let window = NSWindow(contentRect: NSRect(x: 100, y: 500, width: 800, height: 400),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = "\(k_AppName) Log"

        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor

        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.autoresizingMask = [.width, .height]
        textView.backgroundColor = NSColor.textBackgroundColor  // Just to be sure.
        textView.typingAttributes = [
            .foregroundColor: NSColor.labelColor
        ]
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        super.init(window: window)
        NotificationCenter.default.addObserver(self,
          selector: #selector(appendDebugMessage(_:)),
          name: .printDebugMessage,
          object: nil)
        //self.textView.string = DebugLogger.shared.fullLog()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
      super.windowDidLoad()
      textView.backgroundColor = .textBackgroundColor
      textView.typingAttributes = [.foregroundColor: NSColor.labelColor]
      textView.string = DebugLogger.shared.fullLog()
    }

    @objc func appendDebugMessage(_ notification: Notification) {
        guard let message = notification.object as? String else { return }
        DispatchQueue.main.async {
            let dynamicAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.labelColor
            ]
            let attributedMessage = NSAttributedString(string: message + "\n", attributes: dynamicAttributes)
            self.textView.textStorage?.append(attributedMessage)
            self.textView.scrollRangeToVisible(NSRange(location: self.textView.string.count, length: 0))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

func PTdebugPrint(_ message: String) {
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.timeZone = TimeZone.current // use local time
    let formattedTimestamp = formatter.string(from: timestamp)
    let fullMessage = "\(formattedTimestamp): \(message)"
    DebugLogger.shared.log(fullMessage)
}
