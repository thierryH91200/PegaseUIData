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
    
    var name: String = ""
//    @Attribute(.transformable(by: "NSColorValueTransformer")) var color: NSObject? = nil

    var uuid: UUID = UUID()
    
    var account: EntityAccount?
    var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.paymentMode) var preference: EntityPreference?
    @Relationship(inverse: \EntityTransactions.paymentMode) var transactions: [EntityTransactions]?

    public init(name: String, account: EntityAccount? = nil) {
//        public init(name: String, color: NSObject? = nil, account: EntityAccount? = nil) {
        self.name = name
//        self.color = color
        self.account = account
    }

}
