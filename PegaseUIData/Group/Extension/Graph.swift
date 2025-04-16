//
//  Graph.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 19/03/2025.
//

import AppKit
import SwiftUI
import DGCharts

struct DataGraph {
    
    var section = ""
    var name = ""
    var value: Double = 0.0
    var color: NSColor = .orange
    
    init () {
    }
    
    init(section: String = "", name: String, value: Double, color: NSColor = .blue)
    {
        self.section = section
        self.name = name
        self.value  = value
        self.color  = color
    }
}

class CurrencyValueFormatter: NSObject, AxisValueFormatter
{
    let formatter = NumberFormatter()

    public override init() {
        super.init()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: Locale.current.identifier)
        formatter.maximumFractionDigits = 2
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String
    {
        let currency = formatter.string(from: value as NSNumber)!
        return currency
    }
}

class PieValueFormatter: ValueFormatter {
    let formatter: NumberFormatter

    init(currencyCode: String) {
        self.formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
    }

    public func stringForValue(_ value: Double,
                                 entry: ChartDataEntry,
                                 dataSetIndex: Int,
                                 viewPortHandler: ViewPortHandler?) -> String {
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
