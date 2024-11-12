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
    }
}

final class ChequeBookManager: NSObject {
    
    // Contexte pour les modifications
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    static let shared = ChequeBookManager()
    private var entities = [EntityCarnetCheques]()
    var currentAccount: EntityAccount?
    
    var viewContext: ModelContext?

    override init() {}
    
    func getAllDatas() -> [EntityCarnetCheques] {
        
        let descriptor = FetchDescriptor<EntityCarnetCheques>(
            predicate: #Predicate { $0.account == currentAccount }
        )

        do {
            entities = try viewContext?.fetch(descriptor) ?? []
        } catch {
            print("Error fetching data from SwiftData")
        }
        
        defaultCarnetCheques()
        return entities
    }
    
    func defaultCarnetCheques() {
        guard entities.isEmpty else { return }
        
        let entityCarnetCheques = EntityCarnetCheques()
        modelContext.insert(entityCarnetCheques)

        entityCarnetCheques.name = localizeString("PaymentMethod.Check")
        entityCarnetCheques.prefix = "CH"
        entityCarnetCheques.numPremier = 1_000
        entityCarnetCheques.numSuivant = 1_000
        entityCarnetCheques.nbCheques = 25
        entityCarnetCheques.account = currentAccount
        entityCarnetCheques.uuid = UUID()
    }
}
