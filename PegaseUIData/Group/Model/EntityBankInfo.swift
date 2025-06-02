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
public class EntityBanqueInfo : Identifiable{
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
    
    var account    : EntityAccount
    
    init(account: EntityAccount)  {
        self.account = account
    }
    init() {
        self.account = CurrentAccountManager.shared.getAccount()!
    }

}

protocol BankManaging {
    func create(account: EntityAccount?) throws -> EntityBanqueInfo
    func update()
    func delete(entity: EntityBanqueInfo)

    func getAllData() -> EntityBanqueInfo? 
    func save() throws
}

final class BankManager : BankManaging {
    
    static let shared = BankManager()
    var entitiesBank = [EntityBanqueInfo]()
    var banks = [EntityBanqueInfo]()
    var bank : EntityBanqueInfo?
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init () {
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
    
    func update() {
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
    }

}

class BankViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var bank: EntityBanqueInfo?
    @Published var banks = [EntityBanqueInfo]()
    private let manager = BankManager()
    @Published var isLoading: Bool = false
    
    init(account: EntityAccount) {
        self.account = account
        self.bank = nil
        
        loadInitialData()
    }
    
    // MARK: Actions utilisateur :
    private func loadInitialData() {
        bank = manager.getAllData()
    }
    
    func add(name: String) {
        do {
            let _ = try manager.create(account: account)
            reloadData()
        } catch EnumError.accountNotFound {
            print("Erreur : compte non trouvé")
        } catch EnumError.saveFailed {
            print("Erreur : échec de la sauvegarde")
        } catch {
            print("Erreur inattendue : \(error)")
        }
    }
    
    func delete() {
        manager.delete(entity: bank!) // Appelle la méthode sans try
        bank = nil
        
        reloadData()      // Recharger depuis la base de données
    }
    
    // MARK: Communication avec les services ou les managers :
    @discardableResult
    func reloadData() -> EntityBanqueInfo {
        bank = manager.getAllData()
        return bank!
    }
    
    func saveChanges() throws {
        try manager.save()
    }
}
