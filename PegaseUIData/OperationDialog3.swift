//
//  OperationDialog3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 27/02/2025.
//

import SwiftUI
import AppKit
import SwiftData
import Observation

// MARK: 1. Composant principal
struct OperationDialogView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: TransactionDataManager
    @EnvironmentObject var formState: TransactionFormState

    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
        
    // États du formulaire déplacés dans un State Object

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête avec information de transaction
            HeaderView(
                title: selectedTransaction?.sousOperations.first?.libelle,
                accountName: currentAccountManager.currentAccount?.name,
                isCreationMode: $isCreationMode
            )
            
            // Formulaire principal
            if formState.selectedAccount != nil {
                TransactionFormView()
                    .environmentObject(formState)
            }
            
            // Section des sous-opérations
            SubOperationsSectionView(
                subOperations: $formState.subOperations,
                currentSubOperation: $formState.currentSousTransaction,
                isShowingDialog: $formState.isShowingDialog
            )
            .environmentObject(formState)

            
            // Boutons d'action
            ActionButtonsView(
                cancelAction: {
                    selectedTransaction = nil
                    isCreationMode = true
                    dismiss()
                },
                saveAction: {
                    saveActions()
                    selectedTransaction = nil
                    isCreationMode = true
                }
            )
        }
        .padding()
        .sheet(isPresented: $formState.isShowingDialog) {
            SubOperationDialog(
                subOperation: $formState.currentSousTransaction,
                isModeCreate: $isCreationMode
            )
            .environmentObject(formState)
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            if newAccount != nil {
                dataManager.transactions = nil
                refreshData()
            }
        }
        .onChange(of: selectedTransaction) { old, newAccount in
            if isCreationMode == false, let transaction = selectedTransaction {
                loadTransactionData(transaction)
            }
        }

        .onAppear {
            Task {
                do {
                    configureDataManagers()
                    try await configureFormState()
                    
                    if isCreationMode == false, let transaction = selectedTransaction {
                        loadTransactionData(transaction)
                    }
                } catch {
                    print("Failed to configure: \(error)")
                }
            }
        }
    }
    
    // Méthodes extraites et simplifiées
    private func configureDataManagers() {
        dataManager.configure(with: modelContext)
        AccountManager.shared.configure(with: modelContext)
        formState.accounts = AccountManager.shared.getAllData()
    }
    
    private func refreshData() {
        ListTransactionsManager.shared.configure(with: modelContext)
        dataManager.transactions = ListTransactionsManager.shared.getAllDatas()
    }
    
    func configureFormState() async throws {
        // Configuration des comptes
        AccountManager.shared.configure(with: modelContext)
        formState.accounts = AccountManager.shared.getAllData()
        formState.selectedAccount = CurrentAccountManager.shared.getAccount()
        
        // Configuration des modes de paiement
        PaymentModeManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            if let modes = PaymentModeManager.shared.getAllDatas(for: account) {
                formState.paymentModes = modes
                // Sélection sécurisée du premier mode de paiement
                formState.selectedMode = modes.first
            }
        }
        // Configuration des différents status
        StatusManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            if let status = StatusManager.shared.getAllDatas(for: account) {
                formState.status = status
                // Sélection sécurisée du premier status
                formState.selectedStatus = status.first
            }
        }
    }
    
    private func loadTransactionData(_ transaction: EntityTransactions) {
        formState.transactionDate        = transaction.dateOperation!.noon
        formState.pointingDate           = transaction.datePointage!.noon
        formState.selectedMode           = transaction.paymentMode
        formState.checkNumber            = Int(transaction.checkNumber) ?? 0
        formState.bankStatement          = Int(transaction.bankStatement)
        formState.selectedStatus         = transaction.status
        formState.selectedAccount        = transaction.account
        formState.currentSousTransaction = transaction.sousOperations.first
        formState.subOperations          = transaction.sousOperations
        formState.currentTransaction     = transaction
    }
    
    func saveActions() {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : Impossible de récupérer le compte")
            return
        }
        
        contextSaveEdition()
        updateTransactionData(account)
        
        do {
            try save()
        } catch {
            print("Erreur lors de l'enregistrement : \(error)")
        }
        resetListTransactions()
    }
    
    func contextSaveEdition() {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : Impossible de récupérer le compte")
            return
        }
        
        // Création d'une nouvelle transaction
        if isCreationMode == true {
            createNewTransaction(account)
            refreshData()
        }
    }
    
    private func createNewTransaction(_ account: EntityAccount) {
        // Création de l'entité transaction
        if let transaction = formState.currentTransaction {
            
            transaction.datePointage = formState.pointingDate.noon
            transaction.dateOperation = formState.transactionDate.noon
            transaction.paymentMode = formState.selectedMode
            transaction.bankStatement = Double(formState.selectedBankStatement) ?? 0
            transaction.status = formState.selectedStatus
            transaction.checkNumber = String(formState.checkNumber)
            modelContext.insert( formState.currentTransaction!)
        }
    }
    
    func printsub() {
        print(  formState.currentTransaction!.sousOperations.first?.libelle ?? "default")
        print(  formState.currentTransaction!.sousOperations.first?.category?.name ?? "nameCat")
        print(  formState.currentTransaction!.sousOperations.first?.category?.rubric?.name ?? "nameRub")
        print(  formState.currentTransaction!.sousOperations.first?.amount ?? 0.0)
    }
    
    private func updateTransactionData(_ account: EntityAccount) {
        formState.currentTransaction?.datePointage = formState.pointingDate.noon
        formState.currentTransaction?.dateOperation = formState.transactionDate.noon
        formState.currentTransaction?.bankStatement = Double(formState.bankStatement)
        formState.currentTransaction?.paymentMode = formState.selectedMode
        formState.currentTransaction?.status = formState.selectedStatus
        formState.currentTransaction?.checkNumber = String(formState.checkNumber)
        formState.currentTransaction?.account = account
        
        printsub()
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func resetListTransactions() {
        formState.bankStatement = 0
        formState.checkNumber = 0
        formState.currentSousTransaction = nil
        formState.selectedMode = nil
    }
}

// MARK: 3. Composant d'en-tête
struct HeaderView: View {
    let title: String?
    let accountName: String?
    @Binding var isCreationMode: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title)
            } else {
                Text("No transaction selected")
            }
            
            if let accountName = accountName {
                Text("Account: \(accountName)")
                    .font(.headline)
            }
            
            Text("\(isCreationMode ? String(localized: "Creation Mode") : String(localized: "Edit Mode"))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCreationMode ? Color.orange : Color.green )
                .accessibilityLabel(isCreationMode ?
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
            modes                 : $formState.paymentModes,
            pointingDate          : $formState.pointingDate,
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


// MARK: 6. Composant des boutons d'action
struct ActionButtonsView: View {
    let cancelAction: () -> Void
    let saveAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: cancelAction) {
                Text("Cancel")
                    .frame(width: 100)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(5)
            }
            .accessibilityLabel(String(localized: "Cancel operation"))
            .accessibilityHint(String(localized: "Double tap to discard changes and close"))
            
            Button(action:
                    saveAction
            ) {
                Text("OK")
                    .frame(width: 100)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(5)
            }
            .accessibilityLabel(String(localized: "Save operation"))
            .accessibilityHint(String(localized: "Double tap to save all changes"))
        }
    }
}

