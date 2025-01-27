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
public class EntityRubric: ObservableObject {
    
    var name: String = ""
    @Attribute(.transformable(by: ColorTransformer.self)) var color: Color
    
    @Attribute(.ephemeral) var total: Double = 0.0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    @Relationship(deleteRule: .cascade) var category: [EntityCategory]?
    var account: EntityAccount?
    
    init( name: String, color: Color, account: EntityAccount) {
        self.name = name
        self.color = color
        self.uuid = UUID()
        self.account = account
    }
}

final class RubricManager {
    
    static let shared = RubricManager()
    
    // Contexte pour les modifications
    var currentAccount: EntityAccount = EntityAccount()
    
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

    @Published private(set) var entitiesRubric: [EntityRubric] = []
        
    func findOrCreate(account: EntityAccount, name: String, color: Color) -> EntityRubric {
        if let existingRubric = find(account: account, name: name) {
            return existingRubric
        }
        
        let newRubric = EntityRubric(name: name, color: color, account: account)
        validContext.insert(newRubric)
        
        entitiesRubric.append(newRubric)
        return newRubric
    }
    
    func find(account: EntityAccount, name: String) -> EntityRubric? {
        return entitiesRubric.first { $0.account?.id == account.id && $0.name == name }
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
            predicate: predicate    //, // Filtrer par le compte
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
//            
//            let entityRubric = NSEntityDescription.insertNewObject(forEntityName: "EntityRubric", into: modelContext) as! EntityRubric

            let name = key["rubrique"] ?? ""
            let color = Color.init( key["color"]!)
//            entityRubric.color = color
//            entityRubric.uuid = UUID()

            let entityRubric = findOrCreate(account: account, name: name, color: color)
            
            let categoryName = key["categorie"] ?? ""
            let categoryObjectif = Double(key["objectif"] ?? "0.0") ?? 0.0
            let entityCategory = EntityCategory(name: categoryName, objectif: categoryObjectif, rubric: entityRubric)
            validContext.insert(entityCategory)
            
            entityRubric.category?.append(entityCategory)
        } else {
            // Adds category to the first rubric in the list
            if let firstRubric = entitiesRubric.first {
                let categoryName = key["categorie"] ?? ""
                let categoryObjectif = Double(key["objectif"] ?? "0.0") ?? 0.0
                let entityCategory = EntityCategory(name: categoryName, objectif: categoryObjectif, rubric: firstRubric)
                validContext.insert(entityCategory)
                
                firstRubric.category?.append(entityCategory)
            }
        }
    }
    
    func loadCSVFile() -> String? {
        guard let url = Bundle.main.url(forResource: "rubrique", withExtension: "csv") else {
            print("Error: File not found.")
            return nil
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            print("Error loading file content: \(error)")
            return nil
        }
    }
    
    func defaultEntity(modelContext: ModelContext) {
        if entitiesRubric.isEmpty {
            let content = loadCSVFile()!
            let csv = CSwiftV(with: content, separator: ";", replace: "\r")
            let keys = csv.keyedRows
            if let keys = keys {
                for key in keys {
                    addRubric(key, account: currentAccount)
                }
            }
            let lhs = currentAccount.uuid
            let predicate = #Predicate<EntityRubric>{ entity in entity.account?.uuid == lhs }

            let descriptor = FetchDescriptor<EntityRubric>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.name, order: .forward)] // Trier par le nom si nécessaire
            )
            
            do {
                entitiesRubric = try validContext.fetch(descriptor)
            } catch {
                print("Error fetching data from SwiftData")
            }
        }
    }
}
