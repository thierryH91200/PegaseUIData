//
//  EntityPaymentMode.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData


@Model public class EntityPaymentMode {
    var name: String?
    var uuid: UUID?
    var account: EntityAccount?
    var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.paymentMode) var preference: EntityPreference?
    @Relationship(inverse: \EntityTransactions.paymentMode) var transactions: [EntityTransactions]?

    public init() {

    }
    
}
