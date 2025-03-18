//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData

//final class TransactionDataManager: ObservableObject {
//    @Published var transactions: [EntityTransactions]? {
//        didSet {
//            // Sauvegarder les modifications dès qu'il y a un changement
//            saveChanges()
//        }
//    }
//    
//    private var modelContext: ModelContext?
//    
//    func configure(with context: ModelContext) {
//        self.modelContext = context
//    }
//    
//    func saveChanges() {
//        guard let context = modelContext else {
//            print("⚠️ modelContext is nil, changes not saved!")
//            return
//        }
//        do {
//            try context.save()
//        } catch {
//            print("❌ Erreur lors de la sauvegarde : \(error.localizedDescription)")
//        }
//    }
//}

struct OperationDialog: View {
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager

    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var transactionDataManager = ListDataManager()
    @StateObject private var formState = TransactionFormState()
    
    var body: some View {
        VStack {
            OperationDialogView()
                .environmentObject(currentAccountManager)
                .environmentObject(formState)

                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .onChange(of: transactionManager.selectedTransaction) {old, new in
                }

        }
        .padding()
    }
}


