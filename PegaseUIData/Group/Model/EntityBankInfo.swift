//
//  EntityBank.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

@Model
final class EntityBanqueInfo : Identifiable{
    var nomBanque  : String  = ""
    var adresse    : String  = ""
    var complement : String  = ""
    var country    : String  = ""
    var cp         : String  = ""
    var email      : String  = ""
    var mobile     : String  = ""
    var town       : String  = ""
    
    var name       : String  = ""
    var fonction   : String  = ""
    var phone      : String  = ""
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    @Relationship var account    : EntityAccount
    
    init(account: EntityAccount)  {
        self.account = account
    }
    @MainActor
    init() {
        self.account = CurrentAccountManager.shared.getAccount()!
    }

}

@MainActor
protocol BankManaging {
    func create(account: EntityAccount?) throws -> EntityBanqueInfo
    func delete(entity: EntityBanqueInfo)

    func getAllData() -> EntityBanqueInfo? 
    func save() throws
}

@MainActor
final class BankManager : BankManaging {
    
    static let shared = BankManager()
    var entitiesBank = [EntityBanqueInfo]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init () {
    }
    func reset() {
        entitiesBank.removeAll()
    }
    
    func create(account: EntityAccount?) throws -> EntityBanqueInfo {
        guard let account = account else {
            throw EnumError.accountNotFound
        }
        
        let entity = EntityBanqueInfo(account: account)
        entity.adresse = ""
        entity.nomBanque = ""
        entity.cp = ""
        entity.email = ""
        entity.fonction = ""
        entity.mobile = ""
        entity.name = ""
        entity.country = ""
        entity.phone = ""
        entity.town = ""
        entity.uuid = UUID()
        
        return entity
    }
    
    func delete(entity: EntityBanqueInfo) {
        modelContext?.delete(entity  )
    }
    
    @discardableResult
    func getAllData() -> EntityBanqueInfo? {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = account.uuid
        let predicate = #Predicate<EntityBanqueInfo> { entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityBanqueInfo.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityBanqueInfo>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entitiesBank = try modelContext?.fetch(fetchDescriptor) ?? []

        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")
            return nil
        }
        return entitiesBank.first
    }
    
    func save() throws {
        
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }

}
