//
//  Graph.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 19/03/2025.
//

import AppKit
import Charts

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
