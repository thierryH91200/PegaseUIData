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


@Model public class EntitySchedule : Identifiable{
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

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount
    var category: EntityCategory?
    @Relationship(inverse: \EntityAccount.compteLie) var linkedAccount: EntityAccount?
    var paymentMode: EntityPaymentMode?
    
    public init() {
        self.account = CurrentAccountManager.shared.getAccount()!
    }

    public init(
        amount: Double,
        dateValeur: Date,
        dateDebut: Date,
        dateFin: Date,
        frequence: Int16,
        libelle: String,
        nextOccurence: Int16,
        occurence: Int16,
        typeFrequence: Int16,
        account: EntityAccount ){
            
            self.amount = amount
            self.libelle = libelle
            self.dateFin = dateFin
            self.dateDebut = dateDebut
            self.dateValeur = dateValeur
            self.frequence =  frequence
            self.libelle = libelle
            self.nextOccurence = nextOccurence
            self.occurence = occurence
            self.typeFrequence = typeFrequence
            self.account = account
    }
}


enum SchedulerError: Error {
    case contextNotConfigured
    case accountNotFound
    case saveFailed
    case fetchFailed
}

final class SchedulerManager {

    static let shared = SchedulerManager()

    @Published var entities = [EntitySchedule]()
    
    var currentAccount: EntityAccount?

    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    init() { }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(account: EntityAccount?, name : String) throws -> EntitySchedule {
        let entity = EntitySchedule()
        validContext.insert(entity)
        try save()
        entities.append(entity)

        return entity
    }
    
    func update(entity: EntitySchedule, name: String) {
        entity.libelle = name
    }

    // Suppression d'une entité
    func remove(entity: EntitySchedule) {

        validContext.delete(entity)
    }

    func fetchEntitySchedules() -> [EntitySchedule] {
        guard let lhs = currentAccount?.uuid else {
            print("Erreur : Aucun compte actif défini.")
            return []
        }
        
        let predicate = #Predicate<EntitySchedule> { entity in
            entity.account.uuid == lhs
        }
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.libelle, order: .forward)]
        )
        
        do {
            return try validContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des données : \(error.localizedDescription)")
            return []
        }
    }
    
    // Récupérer toutes les données filtrées par compte
    func getAllDatas() -> [EntitySchedule]? {

        guard let currentAccount = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = currentAccount.uuid
        let predicate = #Predicate<EntitySchedule>{ entity in
            entity.account.uuid == lhs
        }
        let descriptor = FetchDescriptor<EntitySchedule>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.libelle, order: .forward)]
        )
        
        do {
            // Récupérez les entités en utilisant le FetchDescriptor
            entities = try validContext.fetch( descriptor )
        } catch {
            print("Erreur lors de la récupération des données: \(error)")
            return nil // Retourne nil en cas d'erreur
        }
        return entities
    }
    
    // Créer une sous-opération
    func createSousOperation(for schedule: EntitySchedule) -> EntitySousOperations {
        let sousOperation = EntitySousOperations()
        
        let rubricName = schedule.category?.rubric?.name ?? ""
        _ = schedule.category?.rubric?.color ?? .black
//        let rubricUUID = schedule.category?.rubric?.uuid ?? UUID()
        let rubric = RubricManager.shared.findOrCreate(account: schedule.account, name: rubricName, color: NSColor.blue)
        
        let categoryName = schedule.category?.name ?? ""
        let objectif = schedule.category?.objectif ?? 0.0
//        let categoryUUID = schedule.category?.uuid ?? UUID()
        let category = CategoriesManager.shared.findOrCreate(
            account: schedule.account,
            name: categoryName,
            objectif: objectif,
            rubric: rubric)
        
        sousOperation.category = category
        sousOperation.category?.rubric = rubric
        sousOperation.amount = schedule.amount
        sousOperation.libelle = schedule.libelle
        
        return sousOperation
    }
    
    func createTransaction(for schedule: EntitySchedule, on dateValeur: Date) {
        schedule.nextOccurence += 1

        let transaction = EntityTransactions()
        
        transaction.createAt = Date()
        transaction.updatedAt = Date()
        transaction.dateOperation = dateValeur
        transaction.datePointage = dateValeur
        transaction.account = schedule.account
        transaction.paymentMode = schedule.paymentMode
//        transaction.status = Date() >= dateValeur ? 2 : 1
        transaction.bankStatement = 0
        transaction.uuid = UUID()
        
        let sousOperation = createSousOperation(for: schedule)
        transaction.sousOperations.append( sousOperation )

        if let linkedAccount = schedule.linkedAccount {
            let transferTransaction = EntityTransactions()
            transferTransaction.createAt = transaction.createAt
            transferTransaction.updatedAt = transaction.updatedAt
            transferTransaction.dateOperation = transaction.dateOperation
            transferTransaction.datePointage = transaction.datePointage
            transferTransaction.account = linkedAccount
            transferTransaction.status = transaction.status
            transferTransaction.bankStatement = transaction.bankStatement

            let paymentModeName = transferTransaction.paymentMode?.name ?? ""
            let color = transferTransaction.paymentMode?.color ?? .black
            let paymentModeUUID = transferTransaction.paymentMode?.uuid ?? UUID()
            let paymentMode = PaymentModeManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: Color(color), uuid: paymentModeUUID)
            
            transferTransaction.paymentMode = paymentMode

            let rubric = RubricManager.shared.findOrCreate(account: linkedAccount, name: paymentModeName, color: .black)
            let categoryName = schedule.category?.name ?? "nil"
            let objectif = schedule.category?.objectif ?? 0.0
            let category = CategoriesManager.shared.findOrCreate(
                account: linkedAccount,
                name: categoryName,
                objectif: objectif,
                rubric: rubric)
            
            let transferSousOperation = EntitySousOperations()
            transferSousOperation.category = category
            transferSousOperation.category?.rubric = rubric
            transferSousOperation.amount = -schedule.amount
            
            transferTransaction.sousOperations.append(transferSousOperation)
            transferTransaction.uuid = UUID()
            validContext.insert(transferTransaction) // Ajout explicite dans le contexte

        }
        // Sauvegarde explicite
        if validContext.hasChanges {
            do {
                try validContext.save()
            } catch {
                print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
            }
        }
    }
    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw SchedulerError.saveFailed
        }
    }

}
