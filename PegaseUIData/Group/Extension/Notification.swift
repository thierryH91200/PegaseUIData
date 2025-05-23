//
//  Notification.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 19/03/2025.
//

import Foundation
import SwiftData
import SwiftUI

extension Notification.Name {
    static let importTransaction = Notification.Name("importTransaction")
    static let importTransactionOFX = Notification.Name("importTransactionOFX")
    static let importReleve      = Notification.Name("importReleve")
    static let exportTransaction = Notification.Name("exportTransaction")
    static let exportReleve      = Notification.Name("exportReleve")
        
    static let loadDemoRequested = Notification.Name("loadDemoRequested")
    static let resetDatabaseRequested = Notification.Name("resetDatabaseRequested")

}
