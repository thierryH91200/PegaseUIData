//
//  EntityCarnetCheques.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI

@Model public class EntityCheckBook: Identifiable {
    var name: String = ""
    var nbCheques: Int = 25
    var numPremier: Int = 1
    var numSuivant: Int = 10
    var prefix: String = "CH"
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount?
    
    public init(name: String,
                nbCheques: Int,
                numPremier: Int,
                numSuivant: Int,
                prefix: String,
                account: EntityAccount) {
        
        self.name = name
        self.nbCheques = nbCheques
        self.numPremier = numPremier
        self.numSuivant = numSuivant
        self.prefix = prefix
        
        self.account = account
    }
  
    init() {
        self.account = CurrentAccountManager.shared.getAccount()
    }
}

extension EntityCheckBook {

    var accountName: String {
        account?.identity?.name ?? ""
    }
    
    var accountSurname: String {
        account?.identity?.surName ?? ""
    }
}


// Responsabilités d’un Manager :
//    •    CRUD (Create, Read, Update, Delete) pour les entités.
//    •    Gestion des relations complexes entre les entités (ex. relation entre EntityCarnetCheques et EntityAccount).
//    •    Gestion des erreurs ou des validations métier.
//    •    Interaction avec des services tiers (APIs, bases de données, fichiers, etc.).
//    •    Gestion des états globaux liés à l’application.
final class ChequeBookManager : ObservableObject {
    
    static let shared = ChequeBookManager()
    @Published var entities = [EntityCheckBook]()
    
    var account: EntityAccount?

    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func create(name: String,
                nbCheques: Int = 25,
                numPremier: Int = 1,
                numSuivant: Int = 1,
                prefix: String = "CH") -> EntityCheckBook? {
        // Créez une instance de EntityCarnetCheques
        let entity = EntityCheckBook(
            name: name,
            nbCheques: nbCheques,
            numPremier: numPremier,
            numSuivant: numSuivant,
            prefix: prefix,
            account: CurrentAccountManager.shared.getAccount()!) // Associe le compte actuel
        validContext.insert(entity)
        
        // Sauvegardez le contexte
        save()
        
        return entity
    }

    func getAllDatas() -> [EntityCheckBook]? {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = account.uuid
        let predicate = #Predicate<EntityCheckBook> { entity in entity.account?.uuid == lhs  }
        let sort = [SortDescriptor(\EntityCheckBook.name, order: .forward)]
        
        let descriptor = FetchDescriptor<EntityCheckBook>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entities = try validContext.fetch(descriptor)
        } catch {
            print("Error fetching data from SwiftData: \(error)")
            return nil
        }
        return entities
    }

    func update(entity: EntityCheckBook, name: String) {
        entity.name = name
        save() // Assurez-vous de sauvegarder le contexte après modification
    }

    func delete(entity: EntityCheckBook)
    {
        validContext.undoManager?.beginUndoGrouping()
        validContext.undoManager?.setActionName("DeletePaymentMode")
        validContext.delete(entity)
        validContext.undoManager?.endUndoGrouping()
        
        save()
    }

    
    private func defaultCarnetCheques(for account: EntityAccount) {
        guard entities.isEmpty else { return }
        
        let entityCarnetCheques = EntityCheckBook()
        entityCarnetCheques.name = "Check"
        entityCarnetCheques.prefix = "CH"
        entityCarnetCheques.numPremier = 1
        entityCarnetCheques.numSuivant = 15
        entityCarnetCheques.nbCheques = 25
        entityCarnetCheques.account = account
        entityCarnetCheques.uuid = UUID()
        validContext.insert(entityCarnetCheques)
        
        do {
            try validContext.save()
            entities.append(entityCarnetCheques)
        } catch {
            print("Error saving default Carnet Cheques: \(error)")
        }
    }
    
    func save () {
        do {
            try validContext.save()
        } catch {
            print(" lors de la sauvegarde de l'entité : \(error)")
        }
    }
}

class ChequeBookViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var carnetCheques: [EntityCheckBook] = []
    private let manager: ChequeBookManager
    
    init(account: EntityAccount, manager: ChequeBookManager) {
        self.account = account
        self.manager = manager
        
        Task {
            await loadInitialData()
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        carnetCheques = manager.getAllDatas() ?? []
    }
    
    func add(name: String) {
        if let newCarnet = manager.create(name: name) {
            carnetCheques.append(newCarnet)
        }
    }
    
    func remove(at index: Int) {
        guard carnetCheques.indices.contains(index) else { return }
        let carnet = carnetCheques[index]
        manager.delete(entity: carnet)
        carnetCheques.remove(at: index)
    }
    
    func reloadData() async {
        carnetCheques = manager.getAllDatas() ?? []
    }
}
