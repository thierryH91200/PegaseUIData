//
//  EntityInitAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model public class EntityInitAccount {
    var bic: String = ""
    var cleRib: String = ""
    var codeAccount: String = ""
    var codeBank: String = ""
    var codeGuichet: String = ""
    var iban1: String = ""
    var iban2: String = ""
    var iban3: String = ""
    var iban4: String = ""
    var iban5: String = ""
    var iban6: String = ""
    var iban7: String = ""
    var iban8: String = ""
    var iban9: String = ""

    var engage: Double = 0.0
    var prevu: Double = 0.0
    var realise: Double = 0.0
    
    var account: EntityAccount?
 
    public init() {
        iban1 = "3"
    }
}

final class InitAccountManager: NSObject {
    
    static let shared = InitAccountManager()
    private var entitiesInitAccount = [EntityInitAccount]()
    
    var currentAccount: EntityAccount?

    override init() {
        currentAccount = nil
    }

    // Utiliser un seul contexte pour la gestion des données
    func getAllDatas(for account: EntityAccount, in modelContext: ModelContext) -> EntityInitAccount {
        
        currentAccount = account
        
        let lhs = currentAccount!.uuid.uuidString
        let predicate = #Predicate<EntityInitAccount>{ entity in entity.account!.uuid.uuidString == lhs }

        let descriptor = FetchDescriptor<EntityInitAccount>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.codeAccount)]
        )

        do {
            entitiesInitAccount = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        
        if let firstEntity = entitiesInitAccount.first {
            return firstEntity
        } else {
            return create(numAccount: "", for: account, in: modelContext)
        }
    }

    // Méthode de création d'entité
    func create(numAccount: String = "", for account: EntityAccount, in modelContext: ModelContext) -> EntityInitAccount {
        let entity = EntityInitAccount()
        entity.bic = ""
        entity.cleRib = ""
        entity.codeBank = ""
        entity.codeAccount = numAccount
        entity.codeGuichet = ""
        entity.engage = 0
        entity.iban1 = ""
        entity.iban2 = ""
        entity.iban3 = ""
        entity.iban4 = ""
        entity.iban5 = ""
        entity.iban6 = ""
        entity.iban7 = ""
        entity.iban8 = ""
        entity.iban9 = ""
        entity.prevu = 0
        entity.realise = 0
        entity.account = account // Associe le compte à l'entité
        modelContext.insert(entity)

        entitiesInitAccount.append(entity) // Mise à jour de la liste locale
        
        return entity
    }
}
