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
    var account: EntityAccount?
    
    init( name: String, color: NSColor) {
        self.name = name
        self.color = color
        self.categorie = []
        self.uuid = UUID()
        self.account = CurrentAccountManager.shared.getAccount()!
    }
}

struct Category {
    let name: String
    let type: Int
    let objectif: Int
}

struct Rubrique {
    let name: String
    let color: NSColor
    var categories: [Category]
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
        
        let newRubric = EntityRubric(name: name, color: color)
        validContext.insert(newRubric)
        
        entitiesRubric.append(newRubric)
        return newRubric
    }
    
    func find(account: EntityAccount, name: String) -> EntityRubric? {
        let result = entitiesRubric.first { $0.account?.id == account.id && $0.name == name }
        return result
    }
    
    func remove(entity: EntityRubric) {
        validContext.delete(entity)
        entitiesRubric.removeAll { $0.id == entity.id }
    }
    
    @discardableResult
    func getAllDatas(account: EntityAccount) -> [EntityRubric] {
        
        //        guard let currentAccount = currentAccount else {
        //            print("Aucun compte sélectionné.")
        //            return []
        //        }
        
        let lhs = currentAccount.uuid
        let predicate = #Predicate<EntityRubric>{ entity in entity.account!.uuid == lhs }
        
        let fetchDescriptor = FetchDescriptor<EntityRubric>(
            predicate: predicate
        )
        
        do {
            entitiesRubric = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données avec SwiftData")
        }
        if entitiesRubric.isEmpty {
            defaultEntity(modelContext: validContext)
        }
        return entitiesRubric
    }
    
    fileprivate func addRubric(_ key: [String: String], account: EntityAccount) {
        
        if entitiesRubric.isEmpty {
            
            //            let entityRubric = NSEntityDescription.insertNewObject(forEntityName: "EntityRubric", into: modelContext) as! EntityRubric
            
            let name = key["rubrique"] ?? ""
            let color = Color( key["color"]!)
            
            let entityRubric = findOrCreate(account: account, name: name, color: NSColor.fromSwiftUIColor(color))
            
            let categoryName = key["categorie"] ?? ""
            let categoryObjectif = Double(key["objectif"] ?? "0.0") ?? 0.0
            let entityCategory = EntityCategory(name: categoryName, objectif: categoryObjectif, rubric: entityRubric)
            validContext.insert(entityCategory)
            
            entityRubric.categorie.append(entityCategory)
            do {
                try save()
            } catch {
                print("erreur '", error, "'")
            }
            
        } else {
            // Adds category to the first rubric in the list
            if let firstRubric = entitiesRubric.first {
                let categoryName = key["categorie"] ?? ""
                let categoryObjectif = Double(key["objectif"] ?? "0.0") ?? 0.0
                let entityCategory = EntityCategory(name: categoryName, objectif: categoryObjectif, rubric: firstRubric)
                validContext.insert(entityCategory)
                
                firstRubric.categorie.append(entityCategory)
            }
        }
    }
    
    func loadCSVFile()  {
        guard let url = Bundle.main.url(forResource: "rubrique", withExtension: "csv") else {
            print("Error: File not found.")
            return
        }
        
        importCSV(from: url)
    }
    
    
    func importCSV(from fileURL: URL) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("Erreur de lecture du fichier")
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return }

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
                    currentRubric = EntityRubric(name: rubriqueName, color: nscolor)
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

        try? validContext.save() // Sauvegarder dans SwiftData
    }
    
    func defaultEntity(modelContext: ModelContext) {
    }
    
    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw PaymentModeError.saveFailed
        }
    }
}
