//
//  EntityCategory.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI

@Model public class EntityCategory {

    var name: String
    var objectif: Double = 0.0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    @Relationship(inverse: \EntitySchedule.category) var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.category) var preference: EntityPreference?
    
    var rubric: EntityRubric?
    @Relationship(inverse: \EntitySousOperations.category) var sousOperations: [EntitySousOperations]?
    
    public init(name: String, objectif : Double, rubric: EntityRubric) {
        self.name = name
        self.objectif = objectif
        self.rubric = rubric
        
        self.uuid = UUID()
    }
}

final class CategoriesManager: ObservableObject {
    
    static let shared = CategoriesManager()
    
    @Query private var entities: [EntityCategory] // Liste des entités chargées de manière réactive
   
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func findOrCreate(account: EntityAccount,
                      name: String,
                      objectif: Double,
                      rubric: EntityRubric ) -> EntityCategory {
        if let existingCategory = find(account: account, name: name) {
            return existingCategory
        } else {
            let newCategory = EntityCategory(name: name, objectif: objectif, rubric: rubric)
            validContext.insert(newCategory) // Ajoute l'entité au contexte
            return newCategory
        }
    }

    func find(account: EntityAccount, name: String) -> EntityCategory? {
        entities.first { $0.rubric!.account == account && $0.name == name }
    }

    func findWithRubric(account: EntityAccount, rubric: EntityRubric, name: String) -> EntityCategory? {
        // Supposons que 'category' soit un tableau d'EntityCategory
        let categories = rubric.categorie       // Accès direct, sans conversion
        return categories.first { $0.name == name } ?? categories.first
    }
    
    func remove(entity: EntityCategory) {
        validContext.delete(entity) // Supprime l'entité via le contexte
    }
}
