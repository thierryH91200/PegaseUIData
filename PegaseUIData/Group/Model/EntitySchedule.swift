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
    var amount: Double? = 0.0
    var dateCree: Date?
    var dateDebut: Date?
    var dateFin: Date?
    var dateModifie: Date?
    var dateValeur: Date?
    var frequence: Int16? = 0
    var libelle: String?
    var nextOccurence: Int16? = 0
    var occurence: Int16? = 0
    var typeFrequence: Int16? = 0
    var uuid: UUID?
    var account: EntityAccount?
    var category: EntityCategory?
    @Relationship(inverse: \EntityAccount.compteLie) var compteLie: EntityAccount?
    var paymentMode: EntityPaymentMode?
    
    public init() {

    }
    
}
