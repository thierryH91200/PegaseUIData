//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityTransactions {
    var amount: Double? = 0.0
    var bankStatement: Double? = 0.0
    var checkNumber: String?
    var dateCree: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    var dateModifie: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    var dateOperation: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    var datePointage: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    @Attribute(.ephemeral) var sectionIdentifier: String?
    @Attribute(.ephemeral) var sectionYear: String?
    @Attribute(.ephemeral) var solde: Double? = 0.0
    var statut: Int16? = 0
    var uuid: UUID?
    var account: EntityAccount?
    @Relationship(inverse: \EntityTransactions.operationLiee) var operationLiee: EntityTransactions?
    var paymentMode: EntityPaymentMode?
    var sousOperations: [EntitySousOperations]?
    public init() {

    }
    
}
