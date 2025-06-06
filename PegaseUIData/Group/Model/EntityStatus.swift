//
//  Status.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 12/11/2024.
//

import Foundation
import SwiftData
import SwiftUI

@Model public class EntityStatus {
    
    var name: String = ""
    var type: Int = 0
    @Attribute(.transformable(by: ColorTransformer.self)) var color: NSColor
    
    var account: EntityAccount
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init(name: String, type: Int, color: NSColor ) {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            self.name = name
            self.type = type
            self.color = color
            self.account = EntityAccount()
            return
        }
        self.name = name
        self.type = type
        self.color = color
        self.account = account
    }
    init() {
        name = "test"
        self.color = .black

        self.account = CurrentAccountManager.shared.getAccount()!

    }
}

protocol StatusManaging {
    func create(account: EntityAccount?, name: String, type: Int, color: NSColor) throws -> EntityStatus?
    func find( account: EntityAccount?, name: String) -> EntityStatus?

    func getAllData(for account: EntityAccount?) -> [EntityStatus]?
    func saveContext()
    func defaultStatus(account: EntityAccount)
}

//@Observable
final class StatusManager: StatusManaging {

    static let shared = StatusManager()
    
    var entityStatus = [EntityStatus]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    private init() { }
    
    func create(account: EntityAccount?, name: String, type: Int, color: NSColor) throws -> EntityStatus? {
//        guard let account = account else {
//            throw EnumError.accountNotFound
//        }
                
        let newMode = EntityStatus(name: name, type: type, color: color)
        modelContext?.insert(newMode)
        try save()
        return newMode
    }

    func find( account: EntityAccount? = nil, name: String) -> EntityStatus? {
        
        let account = CurrentAccountManager.shared.getAccount()!
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityStatus> { $0.account.uuid == lhs && $0.name == name }
        let sort = [SortDescriptor(\EntityStatus.name, order: .forward)] // Trier par le nom

        let fetchDescriptor = FetchDescriptor<EntityStatus>(
            predicate: predicate, // Filtrer par le compte
            sortBy: sort )

        do {
            let searchResults = try modelContext?.fetch(fetchDescriptor) ?? []
            let result = searchResults.isEmpty == false ? searchResults.first : nil
            return result
        } catch {
            printTag("Error with request: \(error)")
            return nil
        }
    }

    func getAllData(for account: EntityAccount?) -> [EntityStatus]? {
        guard let account = account else {
            printTag("Erreur : Account est nil")
            return nil
        }

        let accountID = account.uuid
        let predicate = #Predicate<EntityStatus> { entity in entity.account.uuid == accountID }
        let sort = [SortDescriptor(\EntityStatus.type, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityStatus>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entityStatus = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        return entityStatus
    }
    
    func save () throws {
        
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
        }
    }

    func saveContext() {
        if let path = getSQLiteFilePath() {
            printTag("Base de données SQLite : \(path)")
        } else {
            printTag("Erreur : Impossible de récupérer le chemin SQLite")
        }
        
        do {
            try modelContext?.save()
            printTag("Sauvegarde réussie.")
        } catch {
            printTag("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
    
    func defaultStatus(account: EntityAccount) {
        
        entityStatus.removeAll()
        
        // Liste des noms et couleurs des status
        let names = [ String(localized :"Planned"),
                      String(localized :"Engaged"),
                      String(localized :"Executed") ]
        
        let status: [(name: String, type : Int, color: NSColor)] = [
            ( names[0], 0, .blue),
            ( names[1], 1, .green),
            ( names[2], 2, .red)
        ]
        
        // Création des entités
        status.forEach {
            try!  _ = create(account: account, name: $0.name, type: $0.type, color: $0.color)
        }
               
        let lhs = account.uuid
        let predicate = #Predicate<EntityStatus>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityStatus.type, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityStatus>(
            predicate: predicate,
            sortBy: sort )
        
        // Récupération des entités EntityStatus liées au compte actuel
        do {
            entityStatus = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des status : \(error.localizedDescription)")
        }
    }
}

