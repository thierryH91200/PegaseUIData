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
    
    var status: EntityStatus?
    var category: EntityCategory?
    var paymentMode: EntityPaymentMode?
    
    var account: EntityAccount
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init(account: EntityAccount,
                category: EntityCategory? = nil,
                paymentMode: EntityPaymentMode? = nil,
                status: EntityStatus? = nil) {
        
        self.category = category
        self.paymentMode = paymentMode
        self.status = status
        self.signe = true
        
        self.account = account
    }
}

protocol PreferenceManaging {
    func configure(with modelContext: ModelContext)
    func defaultPref(account: EntityAccount) -> EntityPreference?
    func getAllDatas(for account: EntityAccount?) -> EntityPreference?
    func saveContext()
}

// MARK: preferenceManager
final class PreferenceManager: PreferenceManaging {
    
    static let shared = PreferenceManager()
    
    var entityPreferences : [EntityPreference]?
    
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
    
    // MARK: - default
    func defaultPref(account: EntityAccount) -> EntityPreference? {
        // Vérifie si une préférence existe déjà
        if let existingPreference = getAllDatas(for: account) {
            return existingPreference
        }

        let newPreference = EntityPreference(account: account)
        
        if newPreference.category == nil,
           let rubric = RubricManager.shared.getAllDatas(account: account).first {
            if let category = rubric.categorie.sorted(by: { $0.name < $1.name }).first {
                newPreference.category = category
            }
        }
        
        newPreference.paymentMode = PaymentModeManager.shared.getAllDatas(for: account)?.first

        let rubrics = RubricManager.shared.getAllDatas(account: account)
        if let firstRubric = rubrics.first {
            newPreference.category = firstRubric.categorie.first
            newPreference.category?.rubric = firstRubric
        }
        
        // Configuration de status
        StatusManager.shared.configure(with: validContext)
        newPreference.status = StatusManager.shared.getAllDatas(for: account)?.first

        newPreference.signe = true
        newPreference.account = account
        
        validContext.insert(newPreference)
        entityPreferences?.append(newPreference) // Mise à jour du cache local
        
        saveContext()
        return newPreference
    }
    
    func getAllDatas(for account: EntityAccount?) -> EntityPreference? {
        guard let account = account else {
            print("Erreur : Account est nil")
            return nil
        }
        let accountID = account.uuid
        let predicate = #Predicate<EntityPreference> { entity in entity.account.uuid == accountID }
        let fetchDescriptor = FetchDescriptor<EntityPreference>(predicate: predicate)
        
        do {
            entityPreferences = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        return entityPreferences?.first
    }
    func update(status: EntityStatus,
                mode: EntityPaymentMode,
                rubric: EntityRubric,
                category: EntityCategory,
                preference: EntityPreference,
                sign : Bool) async throws {
        
        preference.status = status
        preference.paymentMode = mode
        preference.category?.rubric = rubric
        preference.category = category
        preference.signe = sign

        saveContext()
    }
    
    func saveContext() {
        do {
            try validContext.save()
            print("Sauvegarde réussie.")
        } catch {
            if let path = getSQLiteFilePath() {
                print("Erreur de sauvegarde. Base de données SQLite : \(path)")
            }
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}
