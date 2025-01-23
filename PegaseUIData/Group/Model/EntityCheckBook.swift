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

    var account: EntityAccount
    
    public init(name: String, account: EntityAccount) {
        self.name = name
        self.account = account
    }
  
    init( account: EntityAccount) {
        self.account = account
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

    func create(account: EntityAccount?, name: String ) -> EntityCheckBook? {
        guard let account = account else {
            print("Erreur : l'account est nil.")
            return nil
        }
                
        // Créez une instance de EntityCarnetCheques
        let entity = EntityCheckBook(name: name, account: account)
        validContext.insert(entity)
        
        // Sauvegardez le contexte
        save()
        
        return entity
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

    func getAllDatas(for account: EntityAccount?) async -> [EntityCheckBook] {
        guard let accountUUID = account?.uuid else { return [] }
        
        let predicate = #Predicate<EntityCheckBook> { entity in
            entity.account.uuid == accountUUID
        }
        let descriptor = FetchDescriptor<EntityCheckBook>(predicate: predicate)
        
        do {
            entities = try validContext.fetch(descriptor)
        } catch {
            print("Error fetching data from SwiftData: \(error)")
        }
        
        defaultCarnetCheques(for: account!)
        return entities
    }
    
    private func defaultCarnetCheques(for account: EntityAccount) {
        guard entities.isEmpty else { return }
        
        let entityCarnetCheques = EntityCheckBook(account: account)
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
        carnetCheques = await manager.getAllDatas(for: account)
    }
    
    func add(name: String) {
        if let newCarnet = manager.create(account: account, name: name) {
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
        carnetCheques = await manager.getAllDatas(for: account)
    }
}
