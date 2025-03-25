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
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: ListDataManager
    
    @EnvironmentObject var formState: TransactionFormState
    
    // États du formulaire déplacés dans un State Object
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête avec information de transaction
            HeaderView(
                title: transactionManager.selectedTransaction?.sousOperations.first?.libelle,
                accountName: currentAccountManager.currentAccount?.name
            )
            
            // Formulaire principal
            if formState.selectedAccount != nil {
                TransactionFormView()
            }
            
            // Section des sous-opérations
            SubOperationsSectionView(
                subOperations: $formState.subOperations,
                currentSubOperation: $formState.currentSousTransaction,
                isShowingDialog: $formState.isShowingDialog
            )
            .id(UUID()) // ✅ Force SwiftUI à redessiner la vue
            
            Spacer()
            
            // Boutons d'action
            ActionButtonsView(
                cancelAction: {
                    transactionManager.selectedTransaction = nil
                    transactionManager.isCreationMode = true
                    dismiss()
                },
                saveAction: {
                    saveActions()
                    transactionManager.selectedTransaction = nil
                    transactionManager.isCreationMode = true
                }
            )
        }
        .padding()
        .sheet(isPresented: $formState.isShowingDialog) {
            SubOperationDialog( subOperation: $formState.currentSousTransaction
            )
        }
        
        .onChange(of: formState.subOperations) { oldValue, newValue in
            formState.subOperations = Array(newValue) // Force SwiftUI à détecter un changement
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            if newAccount != nil {
                refreshData()
            }
        }
        .onChange(of: transactionManager.selectedTransaction) { old, newTransaction in
            if transactionManager.isCreationMode == false, let transaction = newTransaction, old != newTransaction {
                loadTransactionData(transaction)
            }
        }
        .onAppear {
            Task {
                do {
                    configureDataManagers()
                    try await configureFormState()
                    
                    if transactionManager.isCreationMode == false, let transaction = transactionManager.selectedTransaction {
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
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas()
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
    
    private func loadTransactionData(_ transaction : EntityTransactions) {
        formState.transactionDate        = transaction.dateOperation?.noon ?? Date()
        formState.pointingDate           = transaction.datePointage?.noon ?? Date()
        formState.selectedMode           = transaction.paymentMode
        formState.checkNumber            = Int(transaction.checkNumber) ?? 0
        formState.bankStatement          = Int(transaction.bankStatement)
        formState.selectedStatus         = transaction.status
        formState.selectedAccount        = transaction.account
        
        DispatchQueue.main.async {
            formState.subOperations = transaction.sousOperations
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            formState.subOperations = transaction.sousOperations
        }
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
        dataManager.loadTransactions()
        resetListTransactions()
    }
    
    func contextSaveEdition() {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : Impossible de récupérer le compte")
            return
        }
        
        // Création d'une nouvelle transaction
        if transactionManager.isCreationMode == true {
            createNewTransaction(account)
//            refreshData()
            dataManager.loadTransactions()

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
            if let transaction = formState.currentTransaction {
                modelContext.insert(transaction)
            }
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
//        printsub()
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func resetListTransactions() {
        formState.bankStatement = 0
        formState.checkNumber = 0
        formState.currentSousTransaction = nil
        formState.selectedMode = nil
        formState.currentTransaction = nil
    }
}

// MARK: 3. Composant d'en-tête
struct HeaderView: View {
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager

    let title: String?
    let accountName: String?
    
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
            
            Text("\(transactionManager.isCreationMode ? String(localized: "Creation Mode") : String(localized: "Edit Mode"))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(transactionManager.isCreationMode ? Color.orange : Color.green )
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
    
    @EnvironmentObject var transactionManager: TransactionSelectionManager

    let cancelAction: () -> Void
    let saveAction:   () -> Void
    
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
            
            Button(action: saveAction ) {
                Text(transactionManager.isCreationMode ? "Add" : "Update")
                    .frame(width: 100)
                    .foregroundColor(.white)
                    .padding()
                    .background(transactionManager.isCreationMode ? .orange : .green)
                    .cornerRadius(5)
            }
            .accessibilityLabel(String(localized: "Save operation"))
            .accessibilityHint(String(localized: "Double tap to save all changes"))
        }
    }
}

