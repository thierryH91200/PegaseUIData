//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 27/02/2025.
//

import SwiftUI
import AppKit
import SwiftData

// 1. Composant principal
struct OperationDialogView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
    
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: TransactionDataManager
    
    // États du formulaire déplacés dans un State Object
    @StateObject private var formState = TransactionFormState()
        
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête avec information de transaction
            HeaderView(
                title: selectedTransaction?.sousOperations.first?.libelle,
                accountName: dataManager.currentAccount?.name,
                isCreationMode: $isCreationMode
            )
            
            // Formulaire principal
            if formState.selectedAccount != nil {
                TransactionFormView(formState: formState)
            }
            
            // Section des sous-opérations
            SubOperationsSectionView(
                subOperations: $formState.subOperations,
                currentSubOperation: $formState.currentSubOperation,
                isShowingDialog: $formState.isShowingDialog
            )
            
            // Boutons d'action
            ActionButtonsView(
                cancelAction: { dismiss() },
                saveAction: { saveActions() }
            )
        }
        .padding()
        .sheet(isPresented: $formState.isShowingDialog) {
            SubOperationDialog(
                subOperation: $formState.currentSubOperation,
                isModeCreate: $isCreationMode
            )
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            if let account = newAccount {
                dataManager.transactions = nil
                dataManager.currentAccount = account
                refreshData()
            }
        }
        .onAppear {
            Task {
                do {
                    configureDataManagers()
                    try await configurePaymentModes()
                    
                    if !isCreationMode, let transaction = selectedTransaction {
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
        if isCreationMode {
            createNewTransaction(account)
        }
    }
    
    private func createNewTransaction(_ account: EntityAccount) {
        // Création de l'entité transaction
        formState.currentTransaction = EntityTransactions()
        formState.currentTransaction?.uuid = UUID()
        formState.currentTransaction?.createAt = Date().noon
        formState.currentTransaction?.updatedAt = Date().noon
        formState.currentTransaction?.account = account
        modelContext.insert(formState.currentTransaction!)
        
        // Création de la sous-transaction
        formState.currentSousTransaction = EntitySousOperations()
        if let subOp = formState.currentSubOperation {
            formState.currentSousTransaction?.libelle = subOp.libelle
            formState.currentSousTransaction?.amount = subOp.amount
            formState.currentSousTransaction?.category = subOp.category
        }
        modelContext.insert(formState.currentSousTransaction!)
        
        formState.currentTransaction!.addSubOperation(formState.currentSousTransaction!)
    }
    
    private func updateTransactionData(_ account: EntityAccount) {
        formState.currentTransaction?.datePointage = formState.pointingDate.noon
        formState.currentTransaction?.dateOperation = formState.transactionDate.noon
        formState.currentTransaction?.bankStatement = Double(formState.bankStatement)
        formState.currentTransaction?.paymentMode = formState.selectedMode
        formState.currentTransaction?.statut = 3
        formState.currentTransaction?.checkNumber = String(formState.checkNumber)
        formState.currentTransaction?.account = account
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func resetListTransactions() {
        isCreationMode = true
        formState.bankStatement = 0
        formState.checkNumber = 0
    }
}

// 2. État du formulaire
class TransactionFormState: ObservableObject {
    @Published var accounts: [EntityAccount] = []
    @Published var linkedAccount: String = ""
    @Published var transactionDate: Date = Date()
    @Published var paymentModes: [EntityPaymentMode] = []
    @Published var pointingDate: Date = Date()
    @Published var statut: [String] = [
        String(localized: "Planned"),
        String(localized: "Engaged"),
        String(localized: "Executed")
    ]
    
    @Published var amount: String = "75,00 €"
    @Published var isShowingDialog: Bool = false
    
    @Published var subOperations: [EntitySousOperations] = []
    @Published var currentSubOperation: EntitySousOperations?
    @Published var currentTransaction: EntityTransactions?
    @Published var currentSousTransaction: EntitySousOperations?
    
    @Published var selectedBankStatement: String = ""
    @Published var selectedStatut = String(localized: "Engaged")
    @Published var selectedMode: EntityPaymentMode?
    @Published var selectedAccount: EntityAccount?
    
    @Published var bankStatement: Int = 0
    @Published var checkNumber: Int = 0
}

// 3. Composant d'en-tête
struct HeaderView: View {
    let title: String?
    let accountName: String?
    @Binding var isCreationMode: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title)
                //isCreationMode = false
            } else {
                Text("No transaction selected")
//                isCreationMode = true
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

// 4. Composant de formulaire principal
struct TransactionFormView: View {
    @ObservedObject var formState: TransactionFormState
    
    var body: some View {
        TransactionFormViewModel(
            linkedAccount: $formState.accounts,
            transactionDate: $formState.transactionDate,
            modes: $formState.paymentModes,
            pointingDate: $formState.pointingDate,
            statut: $formState.statut,
            bankStatement: $formState.bankStatement,
            checkNumber: $formState.checkNumber,
            amount: $formState.amount,
            selectedBankStatement: $formState.selectedBankStatement,
            selectedStatut: $formState.selectedStatut,
            selectedMode: $formState.selectedMode,
            selectedAccount: $formState.selectedAccount
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Transaction form section"))
    }
}

// 5. Composant pour la section des sous-opérations
struct SubOperationsSectionView: View {
    @Binding var subOperations: [EntitySousOperations]
    @Binding var currentSubOperation: EntitySousOperations?
    @Binding var isShowingDialog: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "Split Transactions"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            List {
                SubOperationListView(
                    subOperations: $subOperations,
                    currentSubOperation: $currentSubOperation,
                    isShowingDialog: $isShowingDialog
                )
            }
            
            HStack {
                Button(action: {
                    currentSubOperation = EntitySousOperations()
                    isShowingDialog = true
                }) {
                    Image(systemName: "plus")
                    Text("Add Sub-operation")
                }
                .padding(.leading)
            }
        }
    }
}

// 6. Composant des boutons d'action
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

//struct OperationDialogView: View {
//    
//    @Environment(\.modelContext) private var modelContext: ModelContext
//    @Environment(\.dismiss) private var dismiss
//    
//    @Binding var selectedTransaction: EntityTransactions?
//    @State private var isCreationMode: Bool
//
//    
//    @EnvironmentObject var currentAccountManager: CurrentAccountManager
//    @EnvironmentObject var dataManager: TransactionDataManager
//
//    @ObservedObject var paymentModeManager = ModeManager()
//    @ObservedObject var rubricManager = RubriqueManager()
//    
//    @State private var accounts : [EntityAccount] = []
//    var entityRubric : [EntityRubric]?
//    var entityCategorie : [EntityCategory]?
//    
//    @State private var currentTransaction : EntityTransactions?
//    @State private var currentSousTransaction : EntitySousOperations?
//
//    @State private var linkedAccount: String = ""
//    @State private var comment = ""
//    @State private var name = ""
//    @State private var surname = ""
//
//    @State private var transactionDate: Date = Date()
//    @State private var paymentModes : [EntityPaymentMode] = []
//
//    @State private var pointingDate: Date = Date()
//    @State private var statut : [String] = [String(localized :"Planned"),
//                                            String(localized :"Engaged"),
//                                            String(localized :"Executed")]
//
//    @State private var amount: String = "75,00 €"
//    @State private var isShowingDialog: Bool = false
//    
//    @State private var subOperations: [EntitySousOperations] = []
//    @State private var currentSubOperation: EntitySousOperations?
//    
//    @State private var selectedBankStatement: String = ""
//    @State private var selectedStatut = String(localized :"Engaged")
//    @State private var selectedMode : EntityPaymentMode?
//    @State private var selectedAccount : EntityAccount?
//    
//    @State private var bankStatement = 0
//    @State private var checkNumber = 0
//    
//    
//    init(selectedTransaction: Binding<EntityTransactions?>, modeCreation: Bool) {
//        self._selectedTransaction = selectedTransaction
//        self.isCreationMode = modeCreation
//        accounts =  []
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(selectedTransaction?.sousOperations.first?.libelle ?? String(localized:"Aucune transaction sélectionnée"))
//
//            if let account = dataManager.currentAccount {
//                Text("Account: \(account.name)")
//                    .font(.headline)
//            }
//
//            // Titre en haut
//            Text("\(isCreationMode ? String(localized:"Create") : String(localized:"Edit"))")
//                .font(.headline)
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color.green)
//                .accessibilityLabel(isCreationMode ?
//                    String(localized: "Create new operation screen") :
//                    String(localized: "Edit operation screen"))
//
//            
//            if selectedAccount != nil {
//                TransactionFormViewModel(
//                    linkedAccount: $accounts,
//                    transactionDate: $transactionDate,
//                    modes: $paymentModes,
//                    pointingDate: $pointingDate,
//                    statut: $statut,
//                    bankStatement: $bankStatement,
//                    checkNumber: $checkNumber,
//                    amount: $amount,
//                    selectedBankStatement: $selectedBankStatement,
//                    selectedStatut: $selectedStatut,
//                    selectedMode: $selectedMode,
//                    selectedAccount: $selectedAccount
//                )
//                .accessibilityElement(children: .contain)
//                .accessibilityLabel(String(localized: "Transaction form section"))
//            }
//
//            // Split Transactions
//            Text(String(localized:"Split Transactions"))
//                .font(.headline)
//                .accessibilityAddTraits(.isHeader)
//
//            List {
//                SubOperationListView(subOperations: $subOperations,
//                                     currentSubOperation: $currentSubOperation,
//                                     isShowingDialog: $isShowingDialog)
//            }
//            .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
//                
//                if let account = newAccount {
//                    dataManager.transactions = nil
//                    dataManager.currentAccount = account
//                    refreshData()
//                }
//            }
//
//            .onAppear {
//                Task {
//                    do {
//                        dataManager.configure(with: modelContext)
//                        AccountManager.shared.configure(with: modelContext)
//                        accounts = AccountManager.shared.getAllData()
//                        try await configurePaymentModes()
//                    } catch {
//                        print("Failed to configure payment modes: \(error)")
//                    }
//                    if isCreationMode == false {
//                        transactionDate = (selectedTransaction?.dateOperation)!
//                        pointingDate = (selectedTransaction?.datePointage)!
//                        selectedMode = selectedTransaction?.paymentMode
//                    }
//                }
//            }
//
//            HStack {
//                Button(action: {
//                    currentSubOperation = EntitySousOperations()
//                    isShowingDialog = true
//                }) {
//                    Image(systemName: "plus")
//                    Text("Add Sub-operation")
//                }
//                .padding(.leading)
//            }
//
//            Spacer()
//
//            // Buttons
//            HStack {
//                Button(action: {
//                    dismiss() // Ferme la vue
//                }) {
//                    Text("Cancel")
//                        .frame(width: 100)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.gray)
//                        .cornerRadius(5)
//                }
//                .accessibilityLabel(String(localized: "Cancel operation"))
//                .accessibilityHint(String(localized: "Double tap to discard changes and close"))
//
//                Button(action: {
//                    saveActions()
//                }) {
//                    Text("OK")
//                        .frame(width: 100)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.green)
//                        .cornerRadius(5)
//                }
//                .accessibilityLabel(String(localized: "Save operation"))
//                .accessibilityHint(String(localized: "Double tap to save all changes"))
//            }
//        }
//        .padding()
//        .sheet(isPresented: $isShowingDialog) {
//            SubOperationDialog(subOperation: $currentSubOperation, isModeCreate: $isCreationMode)
//        }
//    }
//    
//    private func refreshData() {
//        ListTransactionsManager.shared.configure(with: modelContext)
//        dataManager.transactions = ListTransactionsManager.shared.getAllDatas()
//    }
//
//    func configurePaymentModes() async throws {
//        AccountManager.shared.configure(with: modelContext)
//        accounts = AccountManager.shared.getAllData()
//        selectedAccount = CurrentAccountManager.shared.getAccount()
//        
//        PaymentModeManager.shared.configure(with: modelContext)
//        if let account = CurrentAccountManager.shared.getAccount() {
//            if let modes = PaymentModeManager.shared.getAllDatas(for: account) {
//                paymentModes = modes
//                selectedMode = modes.first!
//            } else {
//                paymentModes = [] // Évite un crash
//            }
//        }
//    }
//    // edition = false => creation 1 operation
//    // edition = true => edition 1 to n operation(s)
//    func contextSaveEdition() {
//        
//        guard let account = CurrentAccountManager.shared.getAccount() else {
//            print("Erreur : Impossible de récupérer le compte")
//            return
//        }
//
//        // creation = one operation
//        if isCreationMode == true {
//            
//            // Create entityTransaction
//            currentTransaction = EntityTransactions()
//            currentTransaction?.uuid = UUID()
//            self.currentTransaction?.createAt = Date().noon
//            self.currentTransaction?.updatedAt = Date().noon
//            self.currentTransaction?.account = account
//            modelContext.insert(currentTransaction!)
//            
//            // Create currentSousTransaction
//            self.currentSousTransaction = EntitySousOperations()
//            self.currentSousTransaction?.libelle = currentSubOperation!.libelle
//            self.currentSousTransaction?.amount = currentSubOperation!.amount
//            self.currentSousTransaction?.category = currentSubOperation?.category
//            modelContext.insert(currentSousTransaction!)
//            
//            currentTransaction!.addSubOperation(currentSousTransaction!)
//        }
//    }
//    
//    func saveActions() {
//        
//        guard let account = CurrentAccountManager.shared.getAccount() else {
//            print("Erreur : Impossible de récupérer le compte")
//            return
//        }
//
//        self.contextSaveEdition()
//        
//        currentTransaction?.datePointage  = pointingDate.noon
//        currentTransaction?.dateOperation  = transactionDate.noon
//        currentTransaction?.bankStatement = Double(bankStatement)
//        currentTransaction?.paymentMode = selectedMode
//        currentTransaction?.statut = 3
//        currentTransaction?.checkNumber = String(checkNumber)
//        currentTransaction?.account = account
//        
//        do {
//            try save()
//        } catch {
//            print("Erreur lors de l'enregistrement de la transaction : \(error)")
//        }
//        resetListTransactions()
//    }
//    
//    func save () throws {
//        
//        do {
//            try modelContext.save()
//        } catch {
//            print("Erreur lors de l'enregistrement de la transaction : \(error)")
//        }
//    }
//
//    func resetListTransactions() {
//        isCreationMode = true
//        bankStatement = 0
//        checkNumber = 0
//    }
//}
//
