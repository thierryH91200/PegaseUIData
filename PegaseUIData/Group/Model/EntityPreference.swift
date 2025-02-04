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
    
    var account: EntityAccount
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init(account: EntityAccount,
                category: EntityCategory? = nil,
                paymentMode: EntityPaymentMode? = nil ) {
        self.category = category
        self.paymentMode = paymentMode
        self.statut = 0
        self.signe = true
        
        self.account = account
    }
}

//@Observable
final class PreferenceManager {
    
    static let shared = PreferenceManager()

    private var entityPreference = [EntityPreference]()
    
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

    func getAllDatas(for account: EntityAccount?) async -> EntityPreference? {
        
        // Crée un prédicat pour filtrer les entités par `account`
        let lhs = account!.uuid
        let predicate = #Predicate<EntityPreference>{ entity in entity.account.uuid == lhs }

        let fetchDescriptor = FetchDescriptor<EntityPreference>(
            predicate: predicate)
        
        do {
            entityPreference = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        
        // Si aucun résultat, crée une nouvelle entité liée au compte actuel
        if entityPreference.isEmpty {
            return await create(account: account!)!
        }
        
        return entityPreference.first!
    }
    
    // MARK: - Create
    func create(account: EntityAccount) async -> EntityPreference? {
        
        let newPreference = EntityPreference(account: account)
        
        if let rubric = RubricManager.shared.getAllDatas().sorted(by: { $0.name < $1.name }).first {
           let categories = rubric.categorie
            newPreference.category = categories.sorted { $0.name < $1.name }.first!
        }
        
        let paymentModes = PaymentModeManager.shared.getAllDatas(for: account)
        
        newPreference.paymentMode = paymentModes?.first!
        
        newPreference.statut = 1
        newPreference.signe = true
        newPreference.account = account
        
        validContext.insert(newPreference) // Ajoute l'objet au contexte SwiftData
        entityPreference.append(newPreference) // Mise à jour de la liste locale
        
        saveContext()
        
        return newPreference
    }
    
    func saveContext() {

        let path = getSQLiteFilePath()
        print(path!)
        do {
            try validContext.save()
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur : \(error.localizedDescription)")
        }
    }
}
