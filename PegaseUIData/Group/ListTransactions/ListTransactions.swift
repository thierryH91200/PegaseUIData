//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData

// Gestionnaire de données pour les listTransactions
final class ListDataManager: ObservableObject {
    @Published var listTransactions: [EntityTransactions] = []
     
    private var modelContext: ModelContext?
    
    // Configure le contexte de modèle pour la gestion des données
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // Sauvegarde les modifications dans SwiftData
    func saveChanges() {
        guard let modelContext = modelContext else {
            print("Le contexte de modèle n'est pas initialisé.")
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
    
    @MainActor func deleteTransaction(_ transaction: EntityTransactions) {
        guard let modelContext = modelContext else { return }
               
        modelContext.delete(transaction)
        
        // Rafraîchir complètement la liste après suppression
        saveChanges()
        loadTransactions()  // Recharger la liste des transactions
    }
    
    @MainActor
    func loadTransactions() {
        
        self.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
        objectWillChange.send()
    }
}

