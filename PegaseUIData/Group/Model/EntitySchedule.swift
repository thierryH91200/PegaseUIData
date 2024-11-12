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
    @Environment(\.modelContext) private var modelContext: ModelContext


    // Suppression d'une entité
    func remove(entity: EntitySchedule) {
        modelContext.delete(entity)
    }
    

    func fetchEntitySchedules() -> [EntitySchedule] {
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: #Predicate { $0.account == currentAccount },
            sortBy: [SortDescriptor(\.libelle)]
        )
        do {
            return try viewContext?.fetch(descriptor) ?? []
        } catch {
            print("Erreur lors de la récupération des données")
            return []
        }
    }

    // Récupérer toutes les données filtrées par compte
    func getAllDatas(for account: EntityAccount) -> [EntitySchedule] {
        let fetchRequest = EntitySchedule.fetchRequest()
        fetchRequest.predicate = #Predicate { $0.account == account }
        fetchRequest.sortDescriptors = [SortDescriptor(\.libelle, order: .forward)]
        
        do {
            entities = try modelContext.fetch(fetchRequest)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        return entities
    }
    
    // Créer une sous-opération
    func createSousOperation(for schedule: EntitySchedule) -> EntitySousOperations {
        let sousOperation = EntitySousOperations()
        
        let rubricName = schedule.category?.rubric?.name ?? ""
        let rubricColor = schedule.category?.rubric?.color ?? .label
        let rubricUUID = schedule.category?.rubric?.uuid ?? UUID()
        let rubric = RubricManager.shared.findOrCreate(account: schedule.account!, name: rubricName, color: rubricColor)
        
        let categoryName = schedule.category?.name ?? ""
        let objectif = schedule.category?.objectif ?? ""
        let categoryUUID = schedule.category?.uuid ?? UUID()
        let category = CategoriesManager.shared.findOrCreate(account: schedule.account!, name: categoryName, objectif: objectif, uuid: categoryUUID)
        
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
        transaction.addToSousOperations(sousOperation)

        if let linkedAccount = schedule.compteLie {
            let transferTransaction = EntityTransactions()
            transferTransaction.dateCree = transaction.dateCree
            transferTransaction.dateModifie = transaction.dateModifie
            transferTransaction.dateOperation = transaction.dateOperation
            transferTransaction.datePointage = transaction.datePointage
            transferTransaction.account = linkedAccount
            transferTransaction.statut = transaction.statut
            transferTransaction.bankStatement = transaction.bankStatement

            let paymentModeName = transferTransaction.paymentMode?.name ?? "nil"
            let paymentModeColor = transferTransaction.paymentMode?.color ?? .black
            let paymentModeUUID = transferTransaction.paymentMode?.uuid ?? UUID()
            let paymentMode = PaymentMode.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: paymentModeColor, uuid: paymentModeUUID)
            
            transferTransaction.paymentMode = paymentMode

            let rubric = RubricManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: paymentModeColor, uuid: paymentModeUUID)
            let categoryName = schedule.category?.name ?? "nil"
            let objectif = schedule.category?.objectif ?? ""
            let category = Categories.shared.findOrCreate(account: linkedAccount, name: categoryName, objectif: objectif, uuid: UUID())
            
            let transferSousOperation = EntitySousOperations()
            transferSousOperation.category = category
            transferSousOperation.category?.rubric = rubric
            transferSousOperation.amount = -schedule.amount
            
            transferTransaction.addToSousOperations(transferSousOperation)
            transferTransaction.uuid = UUID()
        }
    }
}
