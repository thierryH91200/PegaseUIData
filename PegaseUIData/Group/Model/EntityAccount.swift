//
//  EntityAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityAccount {
    var dateEcheancier: Date?
    var isAccount: Bool? = false
    var isDemo: Bool?
    var isFolder: Bool?
    var isHeader: Bool? = false
    var isRoot: Bool? = false
    var name: String?
    var nameImage: String?
    @Attribute(.ephemeral) var solde: Double? = 0.0
    var type: Int16? = 0
    var uuid: UUID
    @Relationship(deleteRule: .cascade, inverse: \EntityBank.account) var bank: EntityBank?
    @Relationship(inverse: \EntityBankStatement.account) var bankStatement: [EntityBankStatement]?
    @Relationship(deleteRule: .cascade, inverse: \EntityCarnetCheques.account) var carnetCheques: [EntityCarnetCheques]?
    var children: [EntityAccount]?
    var compteLie: EntitySchedule?
    @Relationship(deleteRule: .cascade, inverse: \EntitySchedule.account) var echeanciers: [EntitySchedule]?
    @Relationship(deleteRule: .cascade, inverse: \EntityIdentity.account) var identity: EntityIdentity?
    @Relationship(deleteRule: .cascade, inverse: \EntityInitAccount.account) var initAccount: EntityInitAccount?
    var parent: EntityAccount?
    @Relationship(deleteRule: .cascade, inverse: \EntityPaymentMode.account) var paymentMode: [EntityPaymentMode]?
    @Relationship(deleteRule: .cascade, inverse: \EntityPreference.account) var preference: EntityPreference?
    @Relationship(deleteRule: .cascade, inverse: \EntityRubric.account) var rubric: [EntityRubric]?
    @Relationship(deleteRule: .cascade, inverse: \EntityTransactions.account) var transactions: [EntityTransactions]?
    public init(uuid: UUID) {
        self.uuid = uuid

    }
    

#warning("The property \"ordered\" on EntityAccount:children is unsupported in SwiftData.")

}
