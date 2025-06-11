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
struct FormTitleView: View {
    let formMode: FormMode

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(8)
        .background(backgroundColor)
        .frame(maxWidth: .infinity)
        .padding()
        .cornerRadius(8)
    }

    private var title: String {
        switch formMode {
        case .create:
            return String(localized:"Mode Creation")
        case .editSingle:
            return String(localized:"Mode Edit")
        case .editMultiple(let ops):
            return String(localized:"Edition multiple \(ops.count) transactions")
        }
    }

    private var backgroundColor: Color {
        switch formMode {
        case .create:
            return .orange
        case .editSingle:
            return .blue
        case .editMultiple:
            return .purple
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
