//
//  EntityRubric.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
////

import AppKit
import SwiftData
import SwiftUI



@Model
public class EntityRubric: Identifiable {
    
    var name: String = ""
    @Attribute(.transformable(by: ColorTransformer.self)) var color: NSColor
    
    @Attribute(.ephemeral) var total: Double = 0.0
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    @Relationship(deleteRule: .cascade) var categorie : [EntityCategory] = []
    var account: EntityAccount
    
    init( name: String, color: NSColor, account: EntityAccount) {
        self.name = name
        self.color = color
        self.categorie = []
        self.uuid = UUID()
        self.account = account
    }
}

final class RubricManager {
    
    static let shared = RubricManager()
    
    // Contexte pour les modifications
    var currentAccount: EntityAccount = EntityAccount()
    var entitiesRubric: [EntityRubric] = []
    
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
    
    func findOrCreate(account: EntityAccount, name: String, color: NSColor) -> EntityRubric {
        if let existingRubric = find(account: account, name: name) {
            return existingRubric
        }
        
        let newRubric = EntityRubric(name: name, color: color, account: account)
        validContext.insert(newRubric)
        
        entitiesRubric.append(newRubric)
        return newRubric
    }
    
    func find(account: EntityAccount, name: String) -> EntityRubric? {
        let result = entitiesRubric.first { $0.account.id == account.id && $0.name == name }
        return result
    }
    
    func remove(entity: EntityRubric) {
        validContext.delete(entity)
        entitiesRubric.removeAll { $0.id == entity.id }
    }
    
    @discardableResult
    func getAllDatas(account: EntityAccount? = nil) -> [EntityRubric] {
        
        var currentAccount : EntityAccount?
        
        if account == nil  {
            currentAccount = CurrentAccountManager.shared.getAccount()!
        }
        else {
            currentAccount = account
        }
        
        let lhs = currentAccount!.uuid
        let predicate = #Predicate<EntityRubric>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityRubric.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityRubric>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            entitiesRubric = try validContext.fetch(fetchDescriptor)

        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")

        }
        if entitiesRubric.isEmpty {
            defaultRubric(for : currentAccount!  )
        }
        return entitiesRubric
    }
        
    func importCSV(from fileURL: URL, account: EntityAccount) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("Erreur de lecture du fichier")
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }
        
        let account = account // ✅ Récupérer une seule fois le compte

        var currentRubric: EntityRubric?

        for (index, line) in lines.enumerated() {
            let columns = line.components(separatedBy: ";")

            if index == 0 { continue } // Ignorer l'en-tête

            if columns.count >= 5 {
                let rubriqueName = columns[0]
                let categoryName = columns[1]
                let objectif = Double(columns[3]) ?? 0.0
                let nscolor = colorFromName(columns[4])

                // Vérifier si la rubrique existe déjà
                if currentRubric?.name != rubriqueName {
                    // Sauvegarder l'ancienne rubrique avant d'en créer une nouvelle
                    if let rubric = currentRubric {
                        validContext.insert(rubric)
                    }
                    // Créer une nouvelle rubrique
                    currentRubric = EntityRubric(name: rubriqueName, color: nscolor, account: account)
                    validContext.insert(currentRubric!)
                }

                // Ajouter une catégorie
                if let rubric = currentRubric {
                    let category = EntityCategory(name: categoryName, objectif: objectif, rubric: rubric)
                    rubric.categorie.append(category)
                }
            }
        }

        // Sauvegarder la dernière rubrique
        if let rubric = currentRubric {
            validContext.insert(rubric)
        }

        do {
            try validContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
    
    func defaultRubric(for account: EntityAccount) {
        guard let url = Bundle.main.url(forResource: "rubrique", withExtension: "csv") else {
            print("Error: File not found.")
            return
        }
        importCSV(from: url, account: account)
    }
    
    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw PaymentModeError.saveFailed
        }
    }
}
