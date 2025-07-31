//
//  Item.swift
//  PegaseUIData
//
//  Created by thierryH24 on 31/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
