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
    var status: Int = 0

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
        self.status = 1
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

//@Observable
final class PreferenceManager: PreferenceManaging {
    
    static let shared = PreferenceManager()
    
    var entityPreference : [EntityPreference]?
    
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
        
        let newPreference = EntityPreference(account: account)
        
        if newPreference.category == nil,
           let rubric = RubricManager.shared.getAllDatas(account: account).sorted(by: { $0.name < $1.name }).first {
            if let category = rubric.categorie.sorted(by: { $0.name < $1.name }).first {
                newPreference.category = category
            }
        }
        
        let paymentModes = PaymentModeManager.shared.getAllDatas(for: account)
        newPreference.paymentMode = paymentModes?.first ?? nil
        
        let rubrics = RubricManager.shared.getAllDatas(account: account)
        newPreference.category?.rubric = rubrics.first ?? nil
        newPreference.category = rubrics.first?.categorie.first ?? nil

        newPreference.status = 1
        newPreference.signe = true
        newPreference.account = account
        
        validContext.insert(newPreference)
        entityPreference?.append(newPreference) // Mise à jour du cache local
        
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
            entityPreference = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")
        }
        return entityPreference?.first ?? defaultPref(account: account)
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
}
