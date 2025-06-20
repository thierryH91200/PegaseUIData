//import Charts
//
//  DateValueFormatter.swift
//  ChartsDemo-OSX
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts

import Foundation
import DGCharts


open class DateValueFormatter: NSObject, AxisValueFormatter
{
    var dateFormatter: DateFormatter
    var miniTime: Double
    var interval: Double
    
    init(miniTime: Double, interval: Double) {
        self.miniTime = miniTime
        self.interval = interval
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "dd/MM"
//        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT+0:00") as TimeZone!
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String
    {
        let date = Date(timeIntervalSince1970: (value * interval ) + miniTime)
        return dateFormatter.string(from: date)
    }
}



//open class CurrencyValueFormatter: NSObject, AxisValueFormatter
//{
//    let formatter = NumberFormatter()
//
//    public override init() {
//        super.init()
//        formatter.numberStyle = .currency
//        formatter.locale = Locale(identifier: Locale.current.identifier)
//        formatter.maximumFractionDigits = 2
//    }
//    
//    public func stringForValue(_ value: Double, axis: AxisBase?) -> String
//    {
//        let currency = formatter.string(from: value as NSNumber)!
//        return currency
//    }
//}
