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
    @Published var listTransactions: [EntityTransaction] = []
     
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
    
    @MainActor func deleteTransaction(_ transaction: EntityTransaction) {
        guard let modelContext = modelContext else { return }
               
        modelContext.delete(transaction)
        
        // Rafraîchir complètement la liste après suppression
        saveChanges()
        loadTransactions()  // Recharger la liste des transactions
    }
    
    @MainActor
    func loadTransactions() {
        
        self.listTransactions = ListTransactionsManager.shared.getAllData(ascending: false)
        objectWillChange.send()
    }
}

enum ColumnWidths {
    static let dateOperation: CGFloat = 120
    static let datePointage: CGFloat = 120
    static let libelle: CGFloat = 150
    static let rubrique: CGFloat = 100
    static let categorie: CGFloat = 100
    static let sousMontant: CGFloat = 100
    static let releve: CGFloat = 120
    static let cheque: CGFloat = 120
    static let statut: CGFloat = 100
    static let modePaiement: CGFloat = 120
    static let montant: CGFloat = 100
}


