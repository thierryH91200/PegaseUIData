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
    }
}

final class InitAccountManager: NSObject {
    
    @Environment(\.modelContext) private var modelContext: ModelContext // Contexte pour les modifications
    var currentAccount: EntityAccount?

    
    static let shared = InitAccountManager()
    var entitiesInitAccount = [EntityInitAccount]()

    var viewContext: ModelContext?

    override init() {
    }
    
    func create(numAccount: String = "") -> EntityInitAccount {
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
        modelContext.insert(entity)

        return entity
    }

    @discardableResult
    func getAllDatas() -> EntityInitAccount {
        
        let descriptor = FetchDescriptor<EntityInitAccount>(
            predicate: #Predicate { $0.account == currentAccount },
            sortBy: [SortDescriptor(\.codeAccount)]
        )

        do {
            entitiesInitAccount = try viewContext?.fetch(descriptor) ?? []
        } catch {
            print("Error fetching data from SwiftData")
        }
        
        if let firstEntity = entitiesInitAccount.first {
            return firstEntity
        } else {
            return create()
        }
    }
}
