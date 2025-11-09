////
////  RectMarker.swift
////  ChartsDemo
////
////  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
////  A port of MPAndroidChart for iOS
////  Licensed under Apache License 2.0
////
////  https://github.com/danielgindi/Charts
////

import DGCharts
import AppKit
import Combine


open nonisolated class RectMarker: MarkerImage
{
    open var color: NSUIColor?
    open var font: NSUIFont?
    open var insets = NSEdgeInsets()
    
    open var miniTime: Double = 0.0
    var interval = 3600.0 * 24.0 // one day
    
    open var minimumSize = CGSize()
    var dateFormatter = DateFormatter()
    
    private let formatterPrice: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .currency
        return f
    }()

    
    fileprivate var label: NSMutableAttributedString?
    fileprivate var _labelSize: CGSize = CGSize()
    
    nonisolated init(color: NSUIColor, font: NSUIFont, insets: NSEdgeInsets, miniTime: Double = 0.0, interval: Double = 0.0)
    {
        super.init()
        
        self.color = color
        self.font = font
        self.insets = insets
        self.miniTime = miniTime
        self.interval = interval
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT+0:00")! as TimeZone
    }
    
    open nonisolated override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
    {
        var offset = CGPoint() //CGPoint(x: 10.0, y:10.0)
        let chart = self.chartView
        var size = self.size
        
        if size.width == 0.0 && image != nil
        {
            size.width = image?.size.width ?? 0.0
        }
        if size.height == 0.0 && image != nil
        {
            size.height = image?.size.height ?? 0.0
        }
        
        let width = size.width
        let height = size.height
        let origin = point

        // Snapshot contentRect max values only if we're on the main thread to respect main-actor isolation
        var contentMaxX: CGFloat? = nil
        var contentMaxY: CGFloat? = nil
        if Thread.isMainThread, let chart {
            let rect = chart.viewPortHandler.contentRect
            contentMaxX = rect.maxX
            contentMaxY = rect.maxY
        }

        if origin.x + offset.x < 0.0 {
            offset.x = -origin.x
        } else if let maxX = contentMaxX, origin.x + width + offset.x > maxX {
            offset.x = -width
        }

        if origin.y + offset.y < 0 {
            offset.y = height
        } else if let maxY = contentMaxY, origin.y + height + offset.y > maxY {
            offset.y = -height
        }
        return offset
    }
    
    open nonisolated override func draw(context: CGContext, point: CGPoint)
    {
        guard let label = label else { return }
        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size
        
        let rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: point.y + offset.y),
            size: size)
        
        context.saveGState()
        if let color = color
        {
            context.beginPath()
            drawRoundedRect(rect: rect, inContext: context, radius: 10.0, borderColor: .black, fillColor: color.cgColor)
            context.fillPath()
        }
        label.draw(in: rect)
        context.restoreGState()
    }
    
    func drawRoundedRect(rect: CGRect, inContext context: CGContext?, radius: CGFloat, borderColor: CGColor, fillColor: CGColor) {
        // 1
        let path = CGMutablePath()
        
        // 2
        path.move( to: CGPoint(x: rect.midX, y: rect.minY ))
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.closeSubpath()
        
        // 3
        context?.setLineWidth(0.5)
        context?.setFillColor(fillColor)
        context?.setStrokeColor(borderColor)
        
        // 4
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
    }

    open nonisolated override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        var str = ""
        let mutableString = NSMutableAttributedString(string: str)

        // Safely capture chartView and its dataSets on the main thread to respect main-actor isolation
        guard let chartView = self.chartView else {
            setLabel(mutableString)
            return
        }

        // Snapshot dataSets synchronously on the main thread to respect main-actor isolation
        let dataSetsSnapshot: [ChartDataSetProtocol] = chartView.data?.dataSets ?? []

        var dataEntryX = 0.0

        for dataSets in dataSetsSnapshot {
            let entries = dataSets.entriesForXValue(entry.x)
            let label = dataSets.label ?? ""
            if let first = entries.first {
                let y = first.y
                let priceString = formatterPrice.string(from: NSNumber(value: y)) ?? "\(y)"
                str = label + " : " + priceString + "\n"
                dataEntryX = first.x
            } else {
                str = label + " :\n"
            }

            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12.0),
                .foregroundColor: dataSets.colors.first ?? NSColor.black
            ]
            let addedString = NSAttributedString(string: str, attributes: labelAttributes)
            mutableString.append(addedString)
        }

        str = "\nDate : " + stringForValue(dataEntryX)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12.0),
            .foregroundColor: NSColor.black
        ]
        let addedString = NSAttributedString(string: str, attributes: labelAttributes)
        mutableString.append(addedString)
        setLabel(mutableString)
    }
    
    open func setLabel(_ newlabel: NSMutableAttributedString)
    {
        label = newlabel
        _labelSize = label!.size()
        
        var size = CGSize()
        size.width = _labelSize.width + self.insets.left + self.insets.right
        size.height = _labelSize.height + self.insets.top + self.insets.bottom
        size.width = max(minimumSize.width, size.width)
        size.height = max(minimumSize.height, size.height)
        self.size = size
    }
    
    func stringForValue(_ value: Double) -> String
    {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let date2 = Date(timeIntervalSince1970: (((value + 1) * interval) + miniTime)  )
        let date = dateFormatter.string(from: date2)
        return  date
    }
    
}
