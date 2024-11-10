//
//  EntitySchedule.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

@Model public class EntitySchedule {
    @Attribute var amount: Double = 0.0
    @Attribute var dateCree: Date = Date()
    @Attribute var dateDebut: Date = Date()
    @Attribute var dateFin: Date = Date()
    @Attribute var dateModifie: Date = Date()
    @Attribute var dateValeur: Date = Date()
    @Attribute var frequence: Int16 = 0
    @Attribute var libelle: String = ""
    @Attribute var nextOccurence: Int16 = 0
    @Attribute var occurence: Int16 = 0
    @Attribute var typeFrequence: Int16 = 0
    @Attribute var uuid: UUID = UUID()
    
    var account: EntityAccount?
    var category: EntityCategory?
    @Relationship(inverse: \EntityAccount.compteLie) var linkedAccount: EntityAccount?
    var paymentMode: EntityPaymentMode?
    
    public init() {
        self.libelle = ""
    }
}
