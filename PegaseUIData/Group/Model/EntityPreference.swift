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
    private var entityPreference = [EntityPreference]()
    
//    override init() {}

    func getAllDatas(for account: EntityAccount?, in modelContext: ModelContext) -> EntityPreference {
        
        // Crée un prédicat pour filtrer les entités par `account`
        
        let lhs = account!.uuid.uuidString
        let predicate = #Predicate<EntityPreference>{ entity in entity.account!.uuid.uuidString == lhs }

        let fetchDescriptor = FetchDescriptor<EntityPreference>(
            predicate: predicate)
        
        do {
            entityPreference = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        
        // Si aucun résultat, crée une nouvelle entité liée au compte actuel
        if entityPreference.isEmpty {
            return create(account: account!, in: modelContext)
        }
        
        return entityPreference.first!
    }
    
    // MARK: - Create
    func create(account: EntityAccount, in modelContext: ModelContext) -> EntityPreference {
        let newPreference = EntityPreference()
        
        if let rubric = RubricManager.shared.getAllDatas(account: account).sorted(by: { $0.name < $1.name }).first,
           let categories = rubric.category {
            newPreference.category = categories.sorted { $0.name < $1.name }.first
        }
        
        let paymentModes = PaymentModeManager.shared.getAllDatas(for: account)
        newPreference.paymentMode = paymentModes.first
        
        newPreference.statut = 1
        newPreference.signe = true
        newPreference.account = account
        
        modelContext.insert(newPreference) // Ajoute l'objet au contexte SwiftData
        entityPreference.append(newPreference) // Mise à jour de la liste locale
        
        return newPreference
    }
}
