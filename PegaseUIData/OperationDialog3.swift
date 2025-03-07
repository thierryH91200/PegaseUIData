//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 27/02/2025.
//

import SwiftUI
import AppKit
import SwiftData

// MARK: 1. Composant principal
struct OperationDialogView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: TransactionDataManager
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
        
    // États du formulaire déplacés dans un State Object
    @StateObject private var formState = TransactionFormState()
        
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
                TransactionFormView(formState: formState)
            }
            
            // Section des sous-opérations
            SubOperationsSectionView(
                subOperations: $formState.subOperations,
                currentSubOperation: $formState.currentSousTransaction,
                isShowingDialog: $formState.isShowingDialog
            )
            
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
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            if let account = newAccount {
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
                    try await configurePaymentModes()
                    
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
    
    func configurePaymentModes() async throws {
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
    }
    
    private func loadTransactionData(_ transaction: EntityTransactions) {
        formState.transactionDate = transaction.dateOperation!
        formState.pointingDate = transaction.datePointage!
        formState.selectedMode = transaction.paymentMode
        formState.checkNumber = Int(transaction.checkNumber)!
        formState.bankStatement = Int(transaction.bankStatement)
        formState.selectedAccount = transaction.account
        formState.currentSousTransaction = transaction.sousOperations.first
        formState.currentTransaction = transaction

        // Ajouter d'autres champs à charger selon besoin
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
        var currentTransaction =  formState.currentTransaction
        currentTransaction = EntityTransactions()
        currentTransaction?.uuid = UUID()
        currentTransaction?.createAt = Date().noon
        currentTransaction?.updatedAt = Date().noon
        currentTransaction?.account = account
        modelContext.insert(currentTransaction!)
        
        // Création de la sous-transaction
        formState.currentSousTransaction = EntitySousOperations()
        if let subOp = formState.currentSousTransaction {
            formState.currentSousTransaction?.libelle = subOp.libelle
            formState.currentSousTransaction?.amount = subOp.amount
            formState.currentSousTransaction?.category = subOp.category
        }
        modelContext.insert(formState.currentSousTransaction!)
        
        formState.currentTransaction = currentTransaction
        
        formState.currentTransaction!.addSubOperation(formState.currentSousTransaction!)
    }
    
    private func updateTransactionData(_ account: EntityAccount) {
        formState.currentTransaction?.datePointage = formState.pointingDate.noon
        formState.currentTransaction?.dateOperation = formState.transactionDate.noon
        formState.currentTransaction?.bankStatement = Double(formState.bankStatement)
        formState.currentTransaction?.paymentMode = formState.selectedMode
        formState.currentTransaction?.status = Int16(formState.selectedStatus)
        formState.currentTransaction?.checkNumber = String(formState.checkNumber)
        formState.currentTransaction?.account = account
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func resetListTransactions() {
        formState.bankStatement = 0
        formState.checkNumber = 0
    }
}

// MARK: 2. État du formulaire
class TransactionFormState: ObservableObject {
    @Published var accounts: [EntityAccount] = []
    @Published var linkedAccount: String = ""
    @Published var transactionDate: Date = Date()
    @Published var paymentModes: [EntityPaymentMode] = []
    @Published var pointingDate: Date = Date()
    @Published var status: [String] = [
        String(localized: "Planned"),
        String(localized: "Engaged"),
        String(localized: "Executed")
    ]
    
    @Published var amount: String = "0,00 €"
    @Published var isShowingDialog: Bool = false
    
    @Published var subOperations: [EntitySousOperations] = []
//    @Published var currentSubOperation: EntitySousOperations?
    @Published var currentTransaction: EntityTransactions?
    @Published var currentSousTransaction: EntitySousOperations?
    
    @Published var selectedBankStatement: String = ""
    @Published var selectedStatus = String(localized: "Engaged")
    @Published var selectedMode: EntityPaymentMode?
    @Published var selectedAccount: EntityAccount?
    
    @Published var bankStatement: Int = 0
    @Published var checkNumber: Int = 0
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
            
            Text("\(isCreationMode ? String(localized: "Create") : String(localized: "Edit"))")
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
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        TransactionFormViewModel(
            linkedAccount: $formState.accounts,
            transactionDate: $formState.transactionDate,
            modes: $formState.paymentModes,
            pointingDate: $formState.pointingDate,
            status: $formState.status,
            bankStatement: $formState.bankStatement,
            checkNumber: $formState.checkNumber,
            amount: $formState.amount,
            selectedBankStatement: $formState.selectedBankStatement,
            selectedStatus: $formState.selectedStatus,
            selectedMode: $formState.selectedMode,
            selectedAccount: $formState.selectedAccount
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
            
            Button(action: saveAction) {
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

