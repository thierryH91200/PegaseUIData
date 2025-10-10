//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData
import Combine



struct OperationDialog: View {
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    @StateObject private var formState = TransactionFormState()
    
    var body: some View {
        VStack {
            OperationDialogView()
                .environmentObject(formState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .onReceive(NotificationCenter.default.publisher(for: .transactionSelectionChanged)) { notification in
                    if let transaction = notification.object as? EntityTransaction {
                        transactionManager.selectedTransaction = transaction
                    } else {
                        transactionManager.selectedTransaction = nil
                    }
                }
                .onChange(of: transactionManager.selectedTransaction) {old, new in
                }

        }
        .padding()
    }
}


//let selectedEntities = transactions.filter { selectedRow.contains($0.id) }



