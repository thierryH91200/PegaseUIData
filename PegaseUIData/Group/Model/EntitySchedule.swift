//
//  EntitySchedule.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model public class EntitySchedule {
    var amount: Double = 0.0
    var dateCree: Date = Date()
    var dateDebut: Date = Date()
    var dateFin: Date = Date()
    var dateModifie: Date = Date()
    var dateValeur: Date = Date()
    var frequence: Int16 = 0
    var libelle: String = ""
    var nextOccurence: Int16 = 0
    var occurence: Int16 = 0
    var typeFrequence: Int16 = 0
    var uuid: UUID = UUID()
    
    var account: EntityAccount?
    var category: EntityCategory?
    @Relationship(inverse: \EntityAccount.compteLie) var linkedAccount: EntityAccount?
    var paymentMode: EntityPaymentMode?
    
    public init() {
        self.libelle = ""
    }
}

final class SchedulerManager {

    static let shared = SchedulerManager()
    private var entities = [EntitySchedule]()

    // Contexte pour les modifications
    @Environment(\.modelContext) private var modelContext: ModelContext
    var currentAccount: EntityAccount?

    // Suppression d'une entité
    func remove(entity: EntitySchedule) {
        modelContext.delete(entity)
    }

    func fetchEntitySchedules() -> [EntitySchedule] {
        
        let lhs = currentAccount!.uuid.uuidString

        let predicate = #Predicate<EntitySchedule>{entity in entity.account?.uuid.uuidString == lhs}
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.libelle)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des données")
            return []
        }
    }

    // Récupérer toutes les données filtrées par compte
    func getAllDatas(for account: EntityAccount?) -> [EntitySchedule] {
                
        let lhs = account!.uuid.uuidString
        let predicate = #Predicate<EntitySchedule>{ entity in entity.account!.uuid.uuidString == lhs }
            
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.libelle, order: .forward)]
        )
        
        do {
            // Récupérez les entités en utilisant le FetchDescriptor
            entities = try modelContext.fetch( descriptor )
        } catch {
            print("Erreur lors de la récupération des données: \(error)")
            entities = [] // Retourne un tableau vide en cas d'erreur
        }
        
        return entities
    }
    
    // Créer une sous-opération
    func createSousOperation(for schedule: EntitySchedule) -> EntitySousOperations {
        let sousOperation = EntitySousOperations()
        
        let rubricName = schedule.category?.rubric?.name ?? ""
        let color = schedule.category?.rubric?.color ?? .black
//        let rubricUUID = schedule.category?.rubric?.uuid ?? UUID()
        let rubric = RubricManager.shared.findOrCreate(account: schedule.account!, name: rubricName, color: color)
        
        let categoryName = schedule.category?.name ?? ""
        let objectif = schedule.category?.objectif ?? 0.0
//        let categoryUUID = schedule.category?.uuid ?? UUID()
        let category = CategoriesManager.shared.findOrCreate(account: schedule.account!, name: categoryName, objectif: objectif)
        
        sousOperation.category = category
        sousOperation.category?.rubric = rubric
        sousOperation.amount = schedule.amount
        sousOperation.libelle = schedule.libelle
        
        return sousOperation
    }
    
    func createTransaction(for schedule: EntitySchedule, on dateValeur: Date) {
        schedule.nextOccurence += 1

        let transaction = EntityTransactions()
        
        transaction.dateCree = Date()
        transaction.dateModifie = Date()
        transaction.dateOperation = dateValeur
        transaction.datePointage = dateValeur
        transaction.account = schedule.account
        transaction.paymentMode = schedule.paymentMode
        transaction.statut = Date() >= dateValeur ? 2 : 1
        transaction.bankStatement = 0
        transaction.uuid = UUID()
        
        let sousOperation = createSousOperation(for: schedule)
        transaction.sousOperations?.append( sousOperation )

        if let linkedAccount = schedule.linkedAccount {
            let transferTransaction = EntityTransactions()
            transferTransaction.dateCree = transaction.dateCree
            transferTransaction.dateModifie = transaction.dateModifie
            transferTransaction.dateOperation = transaction.dateOperation
            transferTransaction.datePointage = transaction.datePointage
            transferTransaction.account = linkedAccount
            transferTransaction.statut = transaction.statut
            transferTransaction.bankStatement = transaction.bankStatement

            let paymentModeName = transferTransaction.paymentMode?.name ?? ""
            let color = transferTransaction.paymentMode?.color ?? .black
            let paymentModeUUID = transferTransaction.paymentMode?.uuid ?? UUID()
            let paymentMode = PaymentModeManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: color, uuid: paymentModeUUID)
            
            transferTransaction.paymentMode = paymentMode

            let rubric = RubricManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: .black)
            let categoryName = schedule.category?.name ?? "nil"
            let objectif = schedule.category?.objectif ?? 0.0
            let category = CategoriesManager.shared.findOrCreate(account: linkedAccount, name: categoryName, objectif: objectif)
            
            let transferSousOperation = EntitySousOperations()
            transferSousOperation.category = category
            transferSousOperation.category?.rubric = rubric
            transferSousOperation.amount = -schedule.amount
            
            transferTransaction.sousOperations?.append(transferSousOperation)
            transferTransaction.uuid = UUID()
        }
    }
}
