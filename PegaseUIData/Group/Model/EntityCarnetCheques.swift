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
    var uuid: UUID = UUID()
    
    var account: EntityAccount?
    
    public init() {
    
    self.name = "test"
}
}
// ObservableObject
final class ChequeBookManager {
    
    static let shared = ChequeBookManager()
    var entities = [EntityCarnetCheques]()
    
//    init() {}

    func getAllDatas(for account: EntityAccount?, in modelContext: ModelContext) -> [EntityCarnetCheques] {

        let ent1 = account?.uuid.uuidString
        
        let predicate1 = #Predicate<EntityCarnetCheques>{ entity in entity.account?.uuid.uuidString  == ent1}

        let descriptor = FetchDescriptor<EntityCarnetCheques>(
            predicate: predicate1
        )

        do {
            entities = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching data from SwiftData")
        }
        
        defaultCarnetCheques(for: account!, in: modelContext)
        return entities
    }
    
    private func defaultCarnetCheques(for account: EntityAccount, in modelContext: ModelContext) {
        guard entities.isEmpty else { return }
        
        let entityCarnetCheques = EntityCarnetCheques()
        entityCarnetCheques.name = localizeString("PaymentMethod.Check")
        entityCarnetCheques.prefix = "CH"
        entityCarnetCheques.numPremier = 1_000
        entityCarnetCheques.numSuivant = 1_000
        entityCarnetCheques.nbCheques = 25
        entityCarnetCheques.account = account
        entityCarnetCheques.uuid = UUID()
        modelContext.insert(entityCarnetCheques)
        
        entities.append(entityCarnetCheques)
    }
}
