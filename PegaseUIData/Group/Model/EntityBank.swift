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
public class EntityBank : Identifiable{
    var adress     : String  = ""
    var bank       : String  = ""
    var complement : String  = ""
    var country    : String  = ""
    var cp         : Int32?  = 0
    var email      : String  = ""
    var fonction   : String  = ""
    var mobile     : String  = ""
    var name       : String  = ""
    var phone      : String  = ""
    var town       : String  = ""
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    var account    : EntityAccount?

    init( account  : EntityAccount)  {
        self.account         = account
    }
}

final class BankManager {
    
    static let shared = Bank()
    var entitiesBank = [EntityBank]()
    var banks = [EntityBank]()
    var bank : EntityBank?

    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }
    
    init () {
    }
    
    func create(account: EntityAccount?) throws -> EntityBank {
        guard let account = account else {
            throw PaymentModeError.accountNotFound
        }
        
        let entity = EntityBank(account: account)
        entity.adress = ""
        entity.bank = ""
        entity.cp = 0
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
    func save() throws {
        
    }

    func delete(entity: EntityBank) {
        validContext.delete(entity  )
    }
    
    @discardableResult
    func getAllDatas(for account: EntityAccount) -> EntityBank? {
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityBank> { entity in
            entity.account?.uuid == lhs
        }
        
        let fetchDescriptor = FetchDescriptor<EntityBank>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        do {
            let entities = try validContext.fetch(fetchDescriptor)
            return entities.first
        } catch {
            print("Error fetching data with SwiftData: \(error)")
            return nil
        }
    }
}

class BankViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var bank: EntityBank?
    @Published var banks = [EntityBank]()
    private let manager = BankManager()
    @Published var isLoading: Bool = false

    init(account: EntityAccount) {
        self.account = account
        self.bank = nil
        
        loadInitialData()
    }
    
    // MARK: Actions utilisateur :
    private func loadInitialData() {
        bank = manager.getAllDatas(for: account)
    }

    func add(name: String) {
        do {
            let _ = try manager.create(account: account)
            reloadData()
        } catch PaymentModeError.accountNotFound {
            print("Erreur : compte non trouvé")
        } catch PaymentModeError.saveFailed {
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
    func reloadData() -> EntityBank {
        bank = manager.getAllDatas(for: account)
        return bank!
    }
    
    func saveChanges() throws {
        try manager.save()
    }
}
