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

    public init(account: EntityAccount, name: String, color: NSColor ) {
        self.name = name
        self.color = color
        self.account = account
    }
}

enum StatusError: Error {
    case contextNotConfigured
    case accountNotFound
    case saveFailed
    case fetchFailed
}

protocol StatusManaging {
    func configure(with modelContext: ModelContext)
    func defaultStatus(account: EntityAccount)
    func getAllDatas(for account: EntityAccount?) -> [EntityStatus]?
    func saveContext()
}

//@Observable
final class StatusManager: StatusManaging {

    static let shared = StatusManager()
    
    var entityStatus = [EntityStatus]()

    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }
    
    private init() { }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityStatus? {
        guard let account = account else {
            throw PaymentModeError.accountNotFound
        }
                
        let newMode = EntityStatus(account: account, name: name, color: color)
        validContext.insert(newMode)
        try save()
        return newMode
    }

    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw StatusError.saveFailed
        }
    }

    func getAllDatas(for account: EntityAccount?) -> [EntityStatus]? {
        guard let account = account else {
            print("Erreur : Account est nil")
            return nil
        }
        let accountID = account.uuid
        let predicate = #Predicate<EntityStatus> { entity in entity.account.uuid == accountID }
        let fetchDescriptor = FetchDescriptor<EntityStatus>(
            predicate: predicate)
        
        do {
            entityStatus = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        return entityStatus
    }
    
    func saveContext() {
        if let path = getSQLiteFilePath() {
            print("Base de données SQLite : \(path)")
        } else {
            print("Erreur : Impossible de récupérer le chemin SQLite")
        }
        
        do {
            try validContext.save()
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
    
    func defaultStatus(account: EntityAccount) {
        
        entityStatus.removeAll()
        
        // Liste des noms et couleurs des méthodes de paiement
        let names = [ String(localized :"Planned"),
                      String(localized :"Engaged"),
                      String(localized :"Executed") ]
        
        let statusModes: [(name: String, type : Int, color: NSColor)] = [
            ( names[0], 0, .orange),
            ( names[1], 1, .green),
            ( names[2], 2, .red)
        ]
        
        // Création des entités de mode de paiement
        statusModes.forEach {
           try!  _ = create(account: account, name: $0.name, color: $0.color)
        }
               
        let lhs = account.uuid
        let predicate = #Predicate<EntityStatus>{ entity in entity.account.uuid == lhs }
                
        let fetchDescriptor = FetchDescriptor<EntityStatus>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        // Récupération des entités EntityStatus liées au compte actuel
        do {
            entityStatus = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }



}

