//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData

final class TransactionDataManager: ObservableObject {
    @Published var transactions: [EntityTransactions]? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    private var modelContext: ModelContext?
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    func saveChanges() {
        guard let context = modelContext else {
            print("⚠️ modelContext is nil, changes not saved!")
            return
        }
        do {
            try context.save()
        } catch {
            print("❌ Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}


struct OperationDialog: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var transactionDataManager = TransactionDataManager()
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode : Bool

    var body: some View {
        VStack {
            OperationDialogView(selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode )
                .environmentObject(transactionDataManager)
                .environmentObject(currentAccountManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}


