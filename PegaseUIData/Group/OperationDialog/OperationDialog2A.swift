//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry Hentic on 03/06/2025.
//

//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry Hentic on 03/06/2025.
//

import SwiftUI
import AppKit
import SwiftData
import Observation

// MARK: 3. Composant d'en-tête
struct HeaderView: View {
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager

    let title: String?
    let accountName: String?
    let transactionCount: Int

    var body: some View {
        VStack(alignment: .leading) {
            if transactionCount > 1 {
                Text("Editing \(transactionCount) transactions")
                    .font(.title2)
            } else if let title = title {
                Text(title)
            } else {
                Text("No transaction selected")
            }

            if let accountName = accountName {
                Text("Account: \(accountName)")
                    .font(.headline)
            }

            Text(transactionManager.isCreationMode ? "Creation Mode" : "Edit Mode")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(transactionManager.isCreationMode ? Color.orange : Color.green)
                .accessibilityLabel(transactionManager.isCreationMode ?
                    String(localized: "Create new operation screen") :
                    String(localized: "Edit operation screen"))
        }
    }
}

// MARK:  4. Composant de formulaire principal
struct TransactionFormView: View {
    @EnvironmentObject var formState: TransactionFormState

    var body: some View {
        TransactionFormViewModel(
            linkedAccount         : $formState.accounts,
            transactionDate       : $formState.transactionDate,
            pointingDate          : $formState.pointingDate,
            modes                 : $formState.paymentModes,
            status                : $formState.status,
            bankStatement         : $formState.bankStatement,
            checkNumber           : $formState.checkNumber,
            amount                : $formState.amount,
            selectedBankStatement : $formState.selectedBankStatement,
            selectedStatus        : $formState.selectedStatus,
            selectedMode          : $formState.selectedMode,
            selectedAccount       : $formState.selectedAccount
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Transaction form section"))
    }
}
