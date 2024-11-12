//
//  EntityPreference.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model public class EntityPreference {
    var signe: Bool = true
    var statut: Int16 = 0

    var category: EntityCategory?
    var paymentMode: EntityPaymentMode?
    
    var account: EntityAccount?

    public init() {

    }
}



//@Observable
final class PreferenceManager {
    
    static let shared = PreferenceManager()
    var currentAccount: EntityAccount?

    @Environment(\.modelContext) private var modelContext: ModelContext // Contexte pour les modifications

    var entityPreference = [EntityPreference]()
    
    init() {
    }
    
    func getAllDatas() -> EntityPreference {
        guard let currentAccount = currentAccount else {
            return entityPreference.first ?? create(account: defaultAccount)
        }
        
        let fetchDescriptor = FetchDescriptor<EntityPreference>(
            predicate: #Predicate { $0.account == currentAccount },
            sortBy: [SortDescriptor(\.category.name, order: .forward)]
        )
        
        do {
            entityPreference = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données dans SwiftData : \(error)")
        }
        
        if entityPreference.isEmpty {
            return create(account: currentAccount)
        }
        return entityPreference.first!
    }
    
    // MARK: - Create
    func create(account: EntityAccount) -> EntityPreference {
        let newPreference = EntityPreference()
        
        var rubric = RubricManager.shared.getAllDatas().sorted { $0.name < $1.name }
        var categories = rubric.first?.category?.allObjects as! [EntityCategory]
        categories = categories.sorted { $0.name! < $1.name! }
        newPreference.category = categories.first
        
        let paymentModes = PaymentModeManager.shared.getAllDatas(for: account)
        newPreference.paymentMode = paymentModes.first
        
        newPreference.statut = 1
        newPreference.signe = true
        newPreference.account = account
        
        modelContext.insert(newPreference) // Ajoute l'objet au contexte SwiftData
        
        return newPreference
    }
}

