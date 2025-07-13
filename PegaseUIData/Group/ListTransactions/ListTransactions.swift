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
         
    var modelContext: ModelContext? {
        DataContext.shared.context
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


