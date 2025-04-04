//
//  PingResponseGraphView.swift
//

import AppKit

class PingResponseGraphView: NSView {

    var historySize: Int {
        didSet {
            if historySize < 1 { historySize = 1 }
            while pingHistory.count > historySize {
                pingHistory.removeFirst()
            }
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }
    }

    var averagePing: Double? {
        guard !pingHistory.isEmpty else { return nil }
        return pingHistory.reduce(0, +) / Double(pingHistory.count)
    }

    private let graphHeight: CGFloat = k_graphHeight
    private var barWidth: Int
    private var absoluteWidth: CGFloat
    private var pingHistory: [Double] = []
    
    // if pinger not active, draw bars in gray
    var pingerActive: Bool = true {
        didSet {
            needsDisplay = true
        }
    }

    init(historySize: Int = defaultHistorySize, barWidth: Int = defaultBarWidth) {
        self.historySize = historySize
        self.barWidth = barWidth
        self.absoluteWidth = Double(historySize * barWidth)
        super.init(frame: NSRect(x: 0, y: 0, width: absoluteWidth, height: graphHeight))
    }
    
    required init?(coder: NSCoder) {
        self.historySize = defaultHistorySize
        self.barWidth = defaultBarWidth
        self.absoluteWidth = CGFloat(historySize * barWidth)
        super.init(coder: coder)
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: absoluteWidth, height: graphHeight)
    }
    
    func addPingResponse(_ response: Double) {
        pingHistory.append(response)
        if pingHistory.count > historySize {
            pingHistory.removeFirst(pingHistory.count - historySize)
        }
        needsDisplay = true
    }
    
    // MARK: - Drawing

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let mainContext = NSGraphicsContext.current?.cgContext else { return }
        
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        guard width > 0, height > 0 else { return }

        guard let offscreen = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        offscreen.setShouldAntialias(k_CGAntiAliasing)
        offscreen.translateBy(x: 0, y: CGFloat(height))
        offscreen.scaleBy(x: 1.0, y: -1.0)
        offscreen.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        offscreen.clear(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        
        drawBars(in: offscreen)
        
        guard let barsImage = offscreen.makeImage() else { return }

        offscreen.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0))
        offscreen.clear(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        offscreen.draw(barsImage, in: bounds)
        offscreen.saveGState()
        offscreen.clip(to: bounds, mask: barsImage)
        offscreen.setBlendMode(.multiply)
        
        let ringPath = CGMutablePath()
        ringPath.addRect(bounds)
        let insetRect = bounds.insetBy(dx: 1, dy: 1)
        let cornerRadius = k_graphCornerRadius - 1
        let innerPath = CGPath(roundedRect: insetRect,
                               cornerWidth: cornerRadius,
                               cornerHeight: cornerRadius,
                               transform: nil)
        ringPath.addPath(innerPath)
        offscreen.addPath(ringPath)
        offscreen.setFillColor(NSColor.black.withAlphaComponent(k_graphBorderAlpha).cgColor)
        offscreen.drawPath(using: .eoFill)
        offscreen.restoreGState()

        guard let finalImage = offscreen.makeImage() else { return }

        mainContext.saveGState()
        mainContext.translateBy(x: 0, y: bounds.height)
        mainContext.scaleBy(x: 1, y: -1)
        mainContext.draw(finalImage, in: bounds)
        mainContext.restoreGState()
    }

    func drawBars(in ctx: CGContext) {
        ctx.setShouldAntialias(k_barsAntiAliasing)
        let H = graphHeight

        for (index, response) in pingHistory.enumerated() {
            let ms = response * 1000
            let xPosition = CGFloat((historySize - pingHistory.count + index) * barWidth)
            var greenHeight: CGFloat = 0
            var yellowHeight: CGFloat = 0
            var redHeight: CGFloat = 0
            
            if ms <= k_fastMs {
                greenHeight = CGFloat(ms / k_fastMs) * H
            } else {
                greenHeight = H
                if ms <= k_mediumMs {
                    yellowHeight = CGFloat((ms - k_fastMs) / k_mediumMs) * H
                } else {
                    yellowHeight = H
                    redHeight = min(CGFloat((ms - k_mediumMs) / k_slowMs) * H, H)
                }
            }
            let color_green = pingerActive ? NSColor.green.withAlphaComponent(k_graphBarAlpha) : NSColor.gray
            let color_yellow = pingerActive ? NSColor.yellow.withAlphaComponent(k_graphBarAlpha) : NSColor.gray
            let color_red = pingerActive ? NSColor.red.withAlphaComponent(k_graphBarAlpha) : NSColor.gray
            
            ctx.setFillColor(color_green.cgColor)
            ctx.fill(CGRect(x: xPosition, y: 0, width: CGFloat(barWidth), height: greenHeight))
            if yellowHeight > 0 {
                ctx.setFillColor(color_yellow.cgColor)
                ctx.fill(CGRect(x: xPosition, y: 0, width: CGFloat(barWidth), height: yellowHeight))
            }
            if redHeight > 0 {
                ctx.setFillColor(color_red.cgColor)
                ctx.fill(CGRect(x: xPosition, y: 0, width: CGFloat(barWidth), height: redHeight))
            }
        }
    }

}
