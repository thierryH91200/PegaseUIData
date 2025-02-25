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
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var transactionDataManager = TransactionDataManager()
    @State private var modeCreate = true
    
    init(modeCreation: Bool) {
        self.modeCreate = modeCreation
    }

    var body: some View {
        VStack {
            OperationDialogView(modeCreation: true)
                .environmentObject(transactionDataManager)
                .environmentObject(currentAccountManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}

final class TransactionDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
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

struct SubOperationListView: View {
    @Binding var subOperations: [EntitySousOperations]
    @Binding var currentSubOperation: EntitySousOperations?
    @Binding var isShowingDialog: Bool

    var body: some View {
        List {
            ForEach(subOperations.indices, id: \.self) { index in
                SubOperationRow(
                    subOperation: subOperations[index],
                    onEdit: {
                        currentSubOperation = subOperations[index]
                        isShowingDialog = true
                    },
                    onDelete: {
                        subOperations.remove(at: index)
                    }
                )
            }
        }
    }
}

struct SubOperationRow: View {
    let subOperation: EntitySousOperations
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(subOperation.libelle)
            Spacer()
            Text("\(subOperation.amount)")
                .foregroundColor(.red)
                .accessibilityLabel(String(localized: "Amount"))
                .accessibilityValue("\(subOperation.amount )")
            Spacer()
                .frame(width: 20)
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .accessibilityLabel(String(localized: "Edit sub-operation"))
            .accessibilityHint(String(localized: "Double tap to edit \(subOperation.libelle)"))
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .accessibilityLabel(String(localized: "Delete sub-operation"))
            .accessibilityHint(String(localized: "Double tap to delete \(subOperation.libelle)"))
        }
    }
}

struct OperationDialogView: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: TransactionDataManager

    @ObservedObject var paymentModeManager = ModeManager()
    @ObservedObject var rubricManager = RubriqueManager()
    
    @State private var accounts : [EntityAccount] = []
    var entityRubric : [EntityRubric]?
    var entityCategorie : [EntityCategory]?
    @State private var currentTransaction : EntityTransactions?
    @State private var currentSousTransaction : EntitySousOperations?

    @State private var linkedAccount: String = ""
    @State private var comment = ""
    @State private var name = ""
    @State private var surname = ""

    @State private var transactionDate: Date = Date()
    @State private var paymentModes : [EntityPaymentMode] = []

    @State private var pointingDate: Date = Date()
    @State private var statut : [String] = [String(localized :"Planned"),
                                            String(localized :"Engaged"),
                                            String(localized :"Executed")]

    @State private var amount: String = "75,00 €"
    @State private var isShowingDialog: Bool = false
    
    @State private var subOperations: [EntitySousOperations] = []
    @State private var currentSubOperation: EntitySousOperations?
    
    @State private var selectedBankStatement: String = ""
    @State private var selectedStatut = String(localized :"Engaged")
    @State private var selectedMode : EntityPaymentMode?
    @State private var selectedAccount : EntityAccount?
    
    @State private var bankStatement = 0
    @State private var checkNumber = 0
    @State private var isCreationMode : Bool
    
    init(modeCreation: Bool) {
        self.isCreationMode = modeCreation
        accounts =  []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let account = dataManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }

            // Titre en haut
            Text("\(isCreationMode ? String(localized:"Create") : String(localized:"Edit"))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .accessibilityLabel(isCreationMode ?
                    String(localized: "Create new operation screen") :
                    String(localized: "Edit operation screen"))

            
            if selectedAccount != nil {
                TransactionFormViewModel(
                    linkedAccount: $accounts,
                    transactionDate: $transactionDate,
                    modes: $paymentModes,
                    pointingDate: $pointingDate,
                    statut: $statut,
                    bankStatement: $bankStatement,
                    checkNumber: $checkNumber,
                    amount: $amount,
                    selectedBankStatement: $selectedBankStatement,
                    selectedStatut: $selectedStatut,
                    selectedMode: $selectedMode,
                    selectedAccount: $selectedAccount
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(String(localized: "Transaction form section"))
            }

            // Split Transactions
            Text(String(localized:"Split Transactions"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            List {
                SubOperationListView(subOperations: $subOperations,
                                     currentSubOperation: $currentSubOperation,
                                     isShowingDialog: $isShowingDialog)
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
                        dataManager.configure(with: modelContext)
                        AccountManager.shared.configure(with: modelContext)
                        accounts = AccountManager.shared.getAllData()
                        try await configurePaymentModes()
                    } catch {
                        print("Failed to configure payment modes: \(error)")
                    }
                }
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

            Spacer()

            // Buttons
            HStack {
                Button(action: {
                    dismiss() // Ferme la vue
                }) {
                    Text("Cancel")
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(5)
                }
                .accessibilityLabel(String(localized: "Cancel operation"))
                .accessibilityHint(String(localized: "Double tap to discard changes and close"))

                Button(action: {
                    saveActions()
                }) {
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
        .padding()
        .sheet(isPresented: $isShowingDialog) {
            SubOperationDialog(subOperation: $currentSubOperation, isModeCreate: $isCreationMode)
        }
    }
    
    private func refreshData() {
        ListTransactionsManager.shared.configure(with: modelContext)
        dataManager.transactions = ListTransactionsManager.shared.getAllDatas()
    }

    func configurePaymentModes() async throws {
        AccountManager.shared.configure(with: modelContext)
        accounts = AccountManager.shared.getAllData()
        selectedAccount = CurrentAccountManager.shared.getAccount()
        
        PaymentModeManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            if let modes = PaymentModeManager.shared.getAllDatas(for: account) {
                paymentModes = modes
                selectedMode = modes.first!
            } else {
                paymentModes = [] // Évite un crash
            }
        }
    }
    // edition = false => creation 1 operation
    // edition = true => edition 1 to n operation(s)
    func contextSaveEdition() {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : Impossible de récupérer le compte")
            return
        }

        // creation = one operation
        if isCreationMode == true {
            
            // Create entityTransaction
            currentTransaction = EntityTransactions()
            currentTransaction?.uuid = UUID()
            self.currentTransaction?.createAt = Date().noon
            self.currentTransaction?.updatedAt = Date().noon
            self.currentTransaction?.account = account
            modelContext.insert(currentTransaction!)
            
            // Create currentSousTransaction
            self.currentSousTransaction = EntitySousOperations()
            self.currentSousTransaction?.libelle = currentSubOperation!.libelle
            self.currentSousTransaction?.amount = currentSubOperation!.amount
            self.currentSousTransaction?.category = currentSubOperation?.category
            modelContext.insert(currentSousTransaction!)
            
            currentTransaction!.addSubOperation(currentSousTransaction!)
        }
    }
    
    func saveActions() {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : Impossible de récupérer le compte")
            return
        }

        self.contextSaveEdition()
        
        currentTransaction?.datePointage  = pointingDate.noon
        currentTransaction?.dateOperation  = transactionDate.noon
        currentTransaction?.bankStatement = Double(bankStatement)
        currentTransaction?.paymentMode = selectedMode
        currentTransaction?.statut = 3
        currentTransaction?.checkNumber = String(checkNumber)
        currentTransaction?.account = account
        
        do {
            try save()
        } catch {
            print("Erreur lors de l'enregistrement de la transaction : \(error)")
        }
        resetListTransactions()
    }
    
    func save () throws {
        
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de l'enregistrement de la transaction : \(error)")
        }
    }

    func resetListTransactions() {
        isCreationMode = true
        bankStatement = 0
        checkNumber = 0
    }
}

struct SubOperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TransactionDataManager

    @Binding var subOperation: EntitySousOperations?
    @Binding var isModeCreate: Bool

    @State private var comment: String = ""
    @State private var rubrique: EntityRubric?
    @State private var category: EntityCategory?
    @State private var amount: String = ""
    
    @State private var isShowingDialog: Bool = false
    
    @State private var selectedRubric    : EntityRubric?
    @State private var selectedCategorie : EntityCategory?
    
    @State private var entityPreference : EntityPreference?
    @State private var entityRubric : [EntityRubric] = []
    @State private var entityCategorie : [EntityCategory] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Split Transactions")
                .font(.headline)
                .padding(.bottom)

            TextField("Comment", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(String(localized: "Comment field"))
                .accessibilityHint(String(localized: "Enter a description for this sub-operation"))

            FormField(label: "Rubric") {
                Picker("", selection: $selectedRubric) {
                    ForEach(entityRubric, id: \.self) { rubric in
                        Text(rubric.name).tag(rubric)
                    }
                }
                .accessibilityLabel(String(localized: "Rubric selection"))
                .accessibilityHint(String(localized: "Choose a rubric for categorizing this sub-operation"))
                .onChange(of: selectedRubric) { oldRubric, newRubric in
                    if let newRubric = newRubric {
                        // Met à jour la liste des catégories en fonction de la rubrique sélectionnée
                        entityCategorie = newRubric.categorie.sorted { $0.name < $1.name }
                        // Réinitialise la sélection de catégorie si elle ne fait plus partie des catégories disponibles
                        if let selected = selectedCategorie,
                           !entityCategorie.contains(where: { $0 == selected }) {
                            selectedCategorie = entityCategorie.first
                        }
                    } else {
                        entityCategorie = []
                        selectedCategorie = nil
                    }
                }
            }

            FormField(label: "Category") {
                Picker("", selection: $selectedCategorie) {
                    ForEach(entityCategorie, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                }
                .accessibilityLabel(String(localized: "Category selection"))
                .accessibilityHint(String(localized: "Choose a category within the selected rubric"))
            }

            TextField("Amount", text: $amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(String(localized: "Amount field"))
                .accessibilityHint(String(localized: "Enter the amount for this sub-operation"))
                .accessibilityValue(amount.isEmpty ?
                    String(localized: "No amount entered") :
                    amount)


            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(5)
                }
                .accessibilityLabel(String(localized: "Cancel sub-operation"))
                .accessibilityHint(String(localized: "Double tap to discard changes"))

                Button(action: {
                        saveSubOperation(subOperation)
                        dismiss() // Ferme la vue après sauvegarde
                }) {
                    Text("OK")
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(5)
                }
            }
        }
        .padding()
        .onAppear {
            configureForm()
            if let subOperation = subOperation {
                amount = String(subOperation.amount)
                comment = subOperation.libelle
                category = subOperation.category
                rubrique = subOperation.category?.rubric
            }
        }
    }
    
    func saveSubOperation(_ subOperation: EntitySousOperations?)
    {
        if isModeCreate == true { // Création
            updateSousOperation(subOperation!)
            modelContext.insert(subOperation!)

        } else { // Modification
            if let existingItem = subOperation {
                updateSousOperation(existingItem)
            }
        }
        try? modelContext.save()
    }
    
    private func updateSousOperation(_ item: EntitySousOperations) {
        item.libelle = comment
        item.category = selectedCategorie
        if let value = Double(amount) {
            item.amount = value
        } else {
            print("Erreur : Le montant saisi n'est pas valide")
        }
    }

    func configureManagers() async throws {
        RubricManager.shared.configure(with: modelContext)
        PreferenceManager.shared.configure(with: modelContext)
        PaymentModeManager.shared.configure(with: modelContext)
    }
    
    func configureForm() {
        Task {
            do {
                try await configureManagers()
                let account = CurrentAccountManager.shared.getAccount()
                self.entityPreference = PreferenceManager.shared.getAllDatas(for: account)
                
                self.entityRubric = RubricManager.shared.getAllDatas()
                
                if let preference = entityPreference, let rubricIndex = entityRubric.firstIndex(where: { $0 == preference.category?.rubric }) {
                    selectedRubric = entityRubric[rubricIndex]
                    entityCategorie = entityRubric[rubricIndex].categorie.sorted { $0.name < $1.name }
                    if let categoryIndex = entityCategorie.firstIndex(where: { $0 === preference.category }) {
                        selectedCategorie = entityCategorie[categoryIndex]
                    }
                }
            } catch {
                print("Failed to configure form: \(error)")
            }
        }
    }
}

