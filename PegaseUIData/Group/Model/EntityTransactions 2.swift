//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData
import AppKit

protocol ListManaging {
    func configure(with modelContext: ModelContext)
    func find(uuid: UUID) -> EntityTransactions?
}


final class ListTransactionsManager: ListManaging {
    
    @EnvironmentObject var formState: TransactionFormState

    static let shared = ListTransactionsManager()
    
    var entities : [EntityTransactions] = []
    var entity : EntityTransactions = EntityTransactions()
    
    private var cache: ListTransactionsCache = ListTransactionsCache()

    var ascending = false
    
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

    @discardableResult
    func createTransactions(formState: TransactionFormState) -> EntityTransactions {
        // Create entityTransaction
        formState.currentTransaction = EntityTransactions()
        formState.currentTransaction?.createAt = Date().noon
        formState.currentTransaction?.updatedAt = Date().noon
        formState.currentTransaction?.uuid = UUID()
        let account = CurrentAccountManager.shared.getAccount()!
        formState.currentTransaction?.account = account
        
        modelContext!.insert(formState.currentTransaction!)

        return formState.currentTransaction!
    }
    
    func find(uuid: UUID) -> EntityTransactions? {
        // Création du prédicat pour filtrer les transactions par UUID
        let predicate = #Predicate<EntityTransactions> { $0.uuid == uuid }

        // Création du FetchDescriptor pour récupérer une entité correspondant à l'UUID
        let fetchDescriptor = FetchDescriptor<EntityTransactions>(
            predicate: predicate
        )

        do {
            // Récupération des entités correspondant au prédicat
            let results = try validContext.fetch(fetchDescriptor)
            
            // Retourner le premier résultat, s'il existe
            return results.first
        } catch {
            print("Erreur lors de la récupération des données avec SwiftData : \(error)")
            return nil
        }
    }
    
    func getAllComments(for account: EntityAccount) throws -> [String] {
        var comments = [String]()
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityTransactions>{ transaction in transaction.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityTransactions.dateOperation, order: .reverse)]
        
        let descriptor = FetchDescriptor<EntityTransactions>(
            predicate: predicate,
            sortBy: sort )

        // Fetch les transactions liées à l'account
        do {
            // Fetch transactions with error handling
            let entityTransactions = try validContext.fetch(descriptor)
            
            // Process transactions and their split operations
            for entityTransaction in entityTransactions {
                let splitTransactions = entityTransaction.sousOperations
                    let splitComments = splitTransactions.compactMap { $0.libelle }
                    comments.append(contentsOf: splitComments)
            }
            
            // Return unique comments
            return comments.uniqueElements
        } catch {
            throw error  // Or handle the error as needed for your use case
        }
    }

    // MARK: getAllDatas
    func getAllDatas( ascending: Bool = true) -> [EntityTransactions] {

        let currentAccount = CurrentAccountManager.shared.getAccount()
        guard let currentAccount = currentAccount else {
            return []
        }
        self.ascending = ascending
        
        // Création du prédicat pour filtrer les transactions par compte
        let currentAccountID = currentAccount.uuid
        let predicate = #Predicate<EntityTransactions> { $0.account.uuid == currentAccountID }
        let sort = [
            SortDescriptor(\EntityTransactions.datePointage, order: ascending ? .forward : .reverse),
            SortDescriptor(\EntityTransactions.dateOperation, order: ascending ? .forward : .reverse) ]

        // Création du FetchDescriptor avec les tri par datePointage et dateOperation
        let fetchDescriptor = FetchDescriptor<EntityTransactions>(
            predicate: predicate,
            sortBy: sort )

        do {
            // Récupération des entités depuis le contexte
            entities = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données avec SwiftData : \(error)")
            return []
        }

        // Ajuste les dates si le compte est en mode démo
        if currentAccount.isDemo {
            adjustDate(for: currentAccount)
        }
        return entities
    }

    // MARK: remove Transaction
    func remove(entity: EntityTransactions) {
        
        do {
            validContext.undoManager?.beginUndoGrouping()
            validContext.undoManager?.setActionName("DeleteTransaction")
            
            // Check if entity is still valid
            validContext.delete(entity)
            try validContext.save()
            validContext.undoManager?.endUndoGrouping()
            
        } catch {
            print("Erreur lors de la suppression: \(error)")
        }
    }
    
    func printTransactions() {
        for entity in entities {
            print(entity.datePointage!)
            print(entity.dateOperation!)
            print(entity.status?.name ?? "no status")
            print(entity.paymentMode?.name ?? "defaultMode")
            let subs = entity.sousOperations
            for sub in subs {
                print(sub.libelle ?? "Sans libellé")
                print(sub.category?.name ?? "Cat def")
                print(sub.category?.rubric!.name ?? "Rub def")
            }
        }
    }

    func adjustDate (for account: EntityAccount) {
        let currentAccount = account

        guard entities.isEmpty == false else {return}
        let diffDate = (entities.first?.datePointage!.timeIntervalSinceNow)!
        for entity in entities {
            entity.datePointage  = (entity.datePointage!  - diffDate).noon
            entity.dateOperation = (entity.dateOperation! - diffDate).noon
        }
        currentAccount.isDemo = false
    }
    
    func clearCache(for account: EntityAccount) async {
        await cache.invalidate(key: account.uuid)
    }
    
    func clearAllCache() async {
        await cache.invalidateAll()
    }
}

class ListTransactionsViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var listTransactions: [EntityTransactions]
    private let manager: ListTransactionsManager
    
    init(account: EntityAccount, manager: ListTransactionsManager) {
        self.account = account
        self.manager = manager
        self.listTransactions = []
        
            loadInitialData()
    }

    private func loadInitialData() {
        listTransactions = manager.getAllDatas()
    }

    
}

