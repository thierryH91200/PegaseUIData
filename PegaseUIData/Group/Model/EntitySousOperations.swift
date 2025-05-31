//
//  EntitySousOperations.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import AppKit


@Model
public class EntitySousOperations: Identifiable {
    var amount: Double = 0.0
    var libelle: String? // Rend optionnel si nécessaire
    
    @Relationship(deleteRule: .nullify) var category: EntityCategory?
    @Relationship(deleteRule: .nullify) var transaction: EntityTransactions?
   
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init(libelle: String? = "Empty", amount: Double = 0.0, category: EntityCategory? = nil, transaction: EntityTransactions? = nil) {
        self.libelle = libelle
        self.amount = amount
        self.category = category
        self.transaction = transaction
    }
    public init() {}
    
    var amountString: String {
        let price = formatPrice(amount)
        return price
    }
    
    func copy(for transaction: EntityTransactions) -> EntitySousOperations {
        let newSous = EntitySousOperations()
        newSous.libelle = self.libelle
        newSous.amount = self.amount
        newSous.category = self.category
        newSous.transaction = transaction
        return newSous
    }
}

final class SubTransactionsManager {
    
    var formState : TransactionFormState = TransactionFormState()

    static let shared =  SubTransactionsManager()
    
    var entities : [EntitySousOperations] = []
    var subOperation : EntitySousOperations?

    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    init() {
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor func createSubTransactions(comment: String,
                               category: EntityCategory,
                               amount: String,
                               formState: TransactionFormState ) {
                
        self.formState = formState
        self.subOperation = formState.currentSousTransaction ?? EntitySousOperations()
        update(comment: comment, category: category, amount: amount)
        
        formState.currentTransaction?.addSubOperation(subOperation!)
        formState.entityTransactions.append(formState.currentTransaction!)
        if formState.currentTransaction?.sousOperations == nil {
            formState.currentTransaction?.sousOperations = []
        }
    }
    
    private func update(comment: String,
                        category: EntityCategory,
                        amount: String) {
        
        if let subOperation = subOperation {
            
            subOperation.libelle = comment
            subOperation.category = category
            if let value = Double(amount) {
                subOperation.amount = value
            } else {
                print("Erreur : Le montant saisi n'est pas valide")
            }
            //        subOperation.transaction = formState.currentTransaction
        }
    }
    // Suppression d'une entité
    func remove(entity: EntitySousOperations) {
        entity.transaction = nil
        validContext.delete(entity)
    }

}
