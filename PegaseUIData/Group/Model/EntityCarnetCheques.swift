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

@Model public class EntityCarnetCheques {
    var name: String = ""
    var nbCheques: Int32 = 0
    var numPremier: Int32 = 0
    var numSuivant: Int32 = 0
    var prefix: String = ""
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount?
    
    public init() {
        
        self.name = "test"
    }
}
// ObservableObject
final class ChequeBookManager {
    
    static let shared = ChequeBookManager()
    var entities = [EntityCarnetCheques]()
    
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
    
    func getAllDatas(for account: EntityAccount?) -> [EntityCarnetCheques] {
        
        let account1 = account?.uuid

        let predicate1 = #Predicate<EntityCarnetCheques>{ entity in entity.account?.uuid  == account1}
        let descriptor = FetchDescriptor<EntityCarnetCheques>(
            predicate: predicate1
        )
        
        do {
            entities = try validContext.fetch(descriptor)
        } catch {
            print("Error fetching data from SwiftData")
        }
        
        defaultCarnetCheques(for: account!)
        return entities
    }
    
    private func defaultCarnetCheques(for account: EntityAccount) {
        guard entities.isEmpty else { return }
        
        let entityCarnetCheques = EntityCarnetCheques()
        entityCarnetCheques.name = "Check"
        entityCarnetCheques.prefix = "CH"
        entityCarnetCheques.numPremier = 1_000
        entityCarnetCheques.numSuivant = 1_000
        entityCarnetCheques.nbCheques = 25
        entityCarnetCheques.account = account
        entityCarnetCheques.uuid = UUID()
        validContext.insert(entityCarnetCheques)
        
        entities.append(entityCarnetCheques)
    }
}
