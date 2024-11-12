//
//  EntityAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI

@Model public class EntityAccount {
       
    var dateEcheancier: Date = Date()
    var isAccount: Bool = false
    var isDemo: Bool = false
    var isFolder: Bool = false
    var isHeader: Bool = false
    var isRoot: Bool = false
    var name: String = ""
    var nameImage: String = ""
    @Attribute(.ephemeral) var solde: Double? = 0.0
    var type: Int = 0
    var uuid: UUID = UUID()
    
    var parent: EntityAccount?
    @Relationship(deleteRule: .cascade, inverse: \EntityBank.account) var bank: EntityBank?
    @Relationship(inverse: \EntityBankStatement.account) var bankStatement: [EntityBankStatement]?
    @Relationship(deleteRule: .cascade, inverse: \EntityCarnetCheques.account) var carnetCheques: [EntityCarnetCheques]?
    var children: [EntityAccount]?
    var compteLie: EntitySchedule?
    
    @Relationship(deleteRule: .cascade, inverse: \EntitySchedule.account) var echeanciers: [EntitySchedule]?
    @Relationship(deleteRule: .cascade, inverse: \EntityIdentity.account) var identity: EntityIdentity?
    @Relationship(deleteRule: .cascade, inverse: \EntityInitAccount.account) var initAccount: EntityInitAccount?
    @Relationship(deleteRule: .cascade, inverse: \EntityPaymentMode.account) var paymentMode: [EntityPaymentMode]?
    @Relationship(deleteRule: .cascade, inverse: \EntityPreference.account) var preference: EntityPreference?
    @Relationship(deleteRule: .cascade, inverse: \EntityRubric.account) var rubric: [EntityRubric]?
    @Relationship(deleteRule: .cascade, inverse: \EntityTransactions.account) var transactions: [EntityTransactions]?

    public init() {
    }
}


final class TypeAccount : NSObject {
    @Environment(\.modelContext) var modelContext

    var body: some View {
        Text("")
    }
    func create(nameAccount: String, nameImage: String, name: String, surname: String, numAccount: String) -> EntityAccount {
        
        let account = EntityAccount()
        account.name = nameAccount
        account.nameImage = nameImage
        account.dateEcheancier = Date().noon
        account.isAccount = true
        account.isRoot = false
        account.uuid = UUID()
        modelContext.insert(account)

        let identity = EntityIdentity()
        identity.name = name
        identity.surName = surname
        identity.account = account
        account.identity = identity
        
        let initAccount = EntityInitAccount()
        initAccount.account = account
        account.initAccount = initAccount
        
        return account
    }

}


final class AccountManager {
    
    // Contexte pour les modifications
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    static let shared = Account()
    var entities = [EntityAccount]()
    
    init() { }

    func getAllData() -> [EntityAccount] {
        // Récupère toutes les instances d'EntityAccount stockées localement dans `entities`
        return entities
    }
    
    // MARK: create account
    func create(nameAccount: String,
                nameImage: String,
                idName: String,
                idPrenom: String,
                numAccount: String) -> EntityAccount {
        // Crée un nouvel objet EntityAccount
        let account = EntityAccount(
            name: nameAccount,
            nameImage: nameImage,
            dateEcheancier: Date().noon,
            isAccount: true,
            isRoot: false,
            uuid: UUID()
        )
        
        // Crée une nouvelle identité et un compte initial pour cet EntityAccount
        let identity = Identity.shared.create(name: idName, prenom: idPrenom)
        identity.account = account
        account.identity = identity
        
        let initAccount = InitAccountManager.shared.create(numAccount: numAccount)
        initAccount.account = account
        account.initAccount = initAccount
        
        // Ajoute le nouveau compte à la liste des entités
        entities.append(account)
        return account
    }
    
    func getRoot() -> [EntityAccount] {
        // Filtre les comptes racine dans la liste d'entités
        return entities.filter { $0.isRoot }
    }
    
    // Juste pour le debug
    func printAccount(entityAccount: EntityAccount, description: String) {
        let name = entityAccount.name
        let identity = entityAccount.identity
        let idName = identity?.name
        let idPrenom = identity?.surName
        let idNumber = entityAccount.initAccount?.codeAccount
        
        print("\(description) : \(name) \(idName) \(idPrenom) \(idNumber)")
    }
}
