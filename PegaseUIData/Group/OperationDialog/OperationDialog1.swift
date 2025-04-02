//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData


struct OperationDialog: View {
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager

    @StateObject private var currentAccountManager = CurrentAccountManager.shared
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


