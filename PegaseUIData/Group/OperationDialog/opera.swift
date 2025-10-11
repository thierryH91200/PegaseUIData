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
//    @EnvironmentObject var dataManager: ListDataManager
    
    @EnvironmentObject var formState: TransactionFormState
    
    @State var setReleve        = Set<Double>()
    @State var setMontant       = Set<Double>()
    @State var setModePaiement  = Set<EntityPaymentMode>()
    @State var setStatut        = Set<EntityStatus>()
    @State var setNumber        = Set<String>()
    @State var setTransfert     = Set<String>()
    @State var setCheck_In_Date = Set<Date>()
    @State var setDateOperation = Set<Date>()
    
    // États du formulaire déplacés dans un State Object
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // En-tête avec information de transaction
            FormTitleView(formMode: transactionManager.formMode)
            Divider()
            
            VStack {
                TransactionFormUnifiedView()
            }
            .onChange(of: transactionManager.selectedTransactions) { old, newSelection in
                formState.updateBatchValues(from: newSelection)
            }
            
            // Section des sous-opérations
            SubOperationsSectionView(
                subOperations       : $formState.subOperations,
                currentSubOperation : $formState.currentSousTransaction,
                isShowingDialog     : $formState.isShowingDialog
            )
            .id(UUID()) // ✅ Force SwiftUI à redessiner la vue
            
            Spacer()
            
            // Boutons d'action
            ActionButtonsView(
                cancelAction: handleCancel,
                saveAction  : handleSave
            )
        }
        .padding()
        .sheet(isPresented: $formState.isShowingDialog) {
            SubOperationDialog( subOperation: $formState.currentSousTransaction )
        }
        
        .onChange(of: formState.subOperations) { oldValue, newValue in
            formState.subOperations = Array(newValue) // Force SwiftUI à détecter un changement
        }
        .onChange(of: currentAccountManager.currentAccountID) { old, newValue in
            if !newValue.isEmpty  {
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
                    printTag("Failed to configure: \(error)")
                }
            }
            setStatut = Set(transactionManager.selectedTransactions.map { $0.status! })
            
            setModePaiement = Set(
                transactionManager.selectedTransactions
                    .compactMap { $0.paymentMode } // Ignore ceux qui sont nil
            )
        }
    }
    
    @ViewBuilder
    private var batchEditSection: some View {
        let uniqueStatus = transactionManager.selectedTransactions.compactMap { $0.status }.uniqueElement
        let uniqueMode = transactionManager.selectedTransactions.compactMap { $0.paymentMode }.uniqueElement
        let uniqueDate = transactionManager.selectedTransactions.map { $0.dateOperation }.uniqueElement
        let uniquePointingDate = transactionManager.selectedTransactions.map { $0.datePointage }.uniqueElement
        let uniqueBankStatement = transactionManager.selectedTransactions.map { $0.bankStatement }.uniqueElement

        BatchEditFormView(
            uniqueStatus: uniqueStatus,
            uniqueMode: uniqueMode,
            uniqueDate: uniqueDate,
            uniquePointingDate: uniquePointingDate,
            uniqueBankStatement: uniqueBankStatement
        )
    }
    
    private func handleCancel() {
        transactionManager.selectedTransaction = nil
        transactionManager.selectedTransactions.removeAll()
        transactionManager.isCreationMode = true
        dismiss()
    }

    private func handleSave() {
        saveActions()
        transactionManager.selectedTransaction = nil
        transactionManager.selectedTransactions.removeAll()
        transactionManager.isCreationMode = true
    }
    
    // Méthodes extraites et simplifiées
    private func configureDataManagers() {
        formState.accounts = AccountManager.shared.getAllData()
    }
    
    private func refreshData() {
        _ = ListTransactionsManager.shared.getAllData()
    }
    
    func configureFormState() async throws {
        
        // Configuration des comptes
        formState.accounts = AccountManager.shared.getAllData()
        formState.selectedAccount = CurrentAccountManager.shared.getAccount()
        
        // Configuration des modes de paiement
        let modes = PaymentModeManager.shared.getAllData()
        formState.paymentModes = modes
        // Sélection sécurisée du premier mode de paiement
        formState.selectedMode = modes.first

        // Configuration des différents status
        if let account = CurrentAccountManager.shared.getAccount() {
            let status = StatusManager.shared.getAllData(for: account)
            formState.status = status
            // Sélection sécurisée du premier status
            formState.selectedStatus = status.first
        }
    }
    
    private func loadTransactionData(_ transaction : EntityTransaction) {
        formState.transactionDate        = transaction.dateOperation.noon
        formState.pointingDate           = transaction.datePointage.noon
        formState.checkNumber            = Int(transaction.checkNumber) ?? 0
        formState.bankStatement          = transaction.bankStatement
        formState.selectedMode           = transaction.paymentMode
        formState.selectedStatus         = transaction.status
        formState.selectedAccount        = transaction.account
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            printTag("DispatchQueue : Nombre de transaction sous-opérations : \(transaction.sousOperations.count)")
            formState.subOperations = transaction.sousOperations
        }
        formState.currentTransaction     = transaction
    }
    
    func saveActions() {
        contextSaveEdition()
        
        if transactionManager.isCreationMode {
            // Mode création : on crée une seule transaction
            let sousTransaction = formState.currentSousTransaction
            guard let sousTransaction else { return }
            let transaction = formState.currentTransaction!

            sousTransaction.transaction = transaction
            modelContext.insert(sousTransaction)
            transaction.addSubOperation(sousTransaction)
            modelContext.insert(transaction)
        } else {
            // Mode édition : modifier toutes les transactions sélectionnées
            for transaction in transactionManager.selectedTransactions {
                transaction.updatedAt = Date().noon
                transaction.datePointage = formState.pointingDate.noon
                transaction.dateOperation = formState.transactionDate.noon
                transaction.paymentMode = formState.selectedMode
                transaction.status = formState.selectedStatus
                transaction.bankStatement = formState.bankStatement
                transaction.checkNumber = String(formState.checkNumber)
                transaction.account = formState.selectedAccount!
            }
        }

        do {
            try save()
            let count = transactionManager.selectedTransactions.count
            printTag("✅ \(count) Transaction(s) sauvegardées")
        } catch {
            printTag("❌ Erreur lors de l'enregistrement : \(error)")
        }

        resetListTransactions()
        NotificationCenter.default.post(name: .transactionsAddEdit, object: nil)
    }
    
    func contextSaveEdition() {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            printTag("Erreur : Impossible de récupérer le compte")
            return
        }
        
        // Création d'une nouvelle transaction
        if transactionManager.isCreationMode == true {
            createNewTransaction(account)
        } else {
            updateTransaction(account)
        }
    }
    
    // Création de l'entité transaction
    private func createNewTransaction(_ account: EntityAccount) {
            
        let transaction  = EntityTransaction()
        
        transaction.dateOperation = formState.transactionDate.noon
        transaction.datePointage = formState.pointingDate.noon
        transaction.paymentMode = formState.selectedMode
        transaction.status = formState.selectedStatus
        transaction.bankStatement = Double(formState.selectedBankStatement) ?? 0
        transaction.checkNumber = String(formState.checkNumber)
        transaction.account = account
        
        formState.currentTransaction = transaction
    }
    
    private func updateTransaction(_ account: EntityAccount) {
        
        let transaction = formState.currentTransaction
        
        transaction?.updatedAt = Date().noon
        
        transaction?.datePointage = formState.pointingDate.noon
        transaction?.dateOperation = formState.transactionDate.noon
        transaction?.paymentMode = formState.selectedMode
        transaction?.status = formState.selectedStatus
        transaction?.bankStatement = formState.bankStatement
        transaction?.checkNumber = String(formState.checkNumber)
        transaction?.account = account
        
        formState.currentTransaction = transaction
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func resetListTransactions() {
        
        let account = CurrentAccountManager.shared.getAccount()
        let entityPreference = PreferenceManager.shared.getAllData(for: account)

        formState.currentTransaction = nil
        formState.currentSousTransaction = nil
        formState.subOperations = []
        formState.selectedMode = entityPreference?.paymentMode
        formState.selectedStatus = entityPreference?.status
        formState.bankStatement = 0.0
        formState.checkNumber = 0
    }
    
    func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        printTag("Time elapsed for \(title): \(timeElapsed) s.")
    }
}

struct UnifiedTransactionEditorView: View {
    @ObservedObject var transactionManager: TransactionSelectionManager
    @ObservedObject var formState: TransactionFormState

    var body: some View {
        Group {
            if transactionManager.selectedTransactions.count > 1 {
                batchEditSection
            } else if formState.selectedAccount != nil {
                TransactionFormView()
            } else {
                Text("No transaction selected.")
                    .foregroundColor(.gray)
            }
        }
    }

    private var batchEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Édition groupée de \(transactionManager.selectedTransactions.count) opérations")
                .font(.headline)
            // Ajoute tes champs de batch ici
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
    }
}

struct HelpButton<Content: View>: View {
    @State private var showHelp = false
    let content: () -> Content

    var body: some View {
        Button(action: { showHelp.toggle() }) {
            Image(systemName: "questionmark.circle")
                .imageScale(.large)
        }
        .popover(isPresented: $showHelp, arrowEdge: .bottom) {
            content()
                .padding()
        }
        .buttonStyle(PlainButtonStyle())
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

struct BatchEditFormView: View {
    @EnvironmentObject var formState: TransactionFormState
    
    let uniqueStatus: EntityStatus?
    let uniqueMode: EntityPaymentMode?
    let uniqueDate: Date?
    let uniquePointingDate: Date?
    let uniqueBankStatement: Double?
    
    private var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Multiple modifications")
                .font(.title3)
            
            modePaiementPicker  //ok
            statutPicker        //ok
            
            DatePicker("Operation Date", selection: $formState.transactionDate, displayedComponents: .date)
                .foregroundStyle(uniqueDate == nil ? .secondary : .primary)
            
            DatePicker("Pointage Date", selection: $formState.pointingDate, displayedComponents: .date)
                .foregroundStyle(uniquePointingDate == nil ? .secondary : .primary)
            
            FormField(label: String(localized: "Bank Statement")) {
                TextField("", text: Binding(
                    get: { String(format: "%.2f", formState.bankStatement) },
                    set: {
                        if let value = Double($0) {
                            formState.bankStatement = value
                        }
                    }
                ))
                .foregroundStyle(uniqueBankStatement == nil ? .secondary : .primary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onAppear {
            if let value = uniqueBankStatement {
                formState.bankStatement = value
            }
        }
        
    }
    
    // Picker du mode de paiement
    private var modePaiementPicker: some View {
        let binding = Binding<EntityPaymentMode?>(
            get: { uniqueMode },
            set: { newValue in
                formState.selectedMode = newValue
            }
        )
        
        return Picker("Payment method", selection: binding) {
            Text("Multiple value").tag(nil as EntityPaymentMode?)
            ForEach(formState.paymentModes, id: \.self) { mode in
                Text(mode.name).tag(mode)
            }
        }
    }
    
    // Picker du statut
    private var statutPicker: some View {
        let binding = Binding<EntityStatus?>(
            get: { uniqueStatus },
            set: { newValue in
                formState.selectedStatus = newValue
            }
        )
        
        return HStack(alignment: .top, spacing: 8) {
            Picker("Status", selection: binding) {
                Text("Multiple value").tag(nil as EntityStatus?)
                ForEach(formState.status, id: \.self) { status in
                    Text(status.name).tag(Optional(status)) // important : Optional()
                }
            }
            HelpButton {
                VStack(alignment: .leading, spacing: 6) {
                    Text("• **Planned**: estimated check-in date, editable amount")
                    Text("• **Committed**: estimated clocking date, modifiable amount")
                    Text("• **Pointed**: exact date of the statement, amount not modifiable")
                    Divider()
                    Text("💡 **Keyboard shortcuts**: P = Planned, E = Committed, T = Pointed")
                }
                .font(.system(size: 12))
                .padding(8)
            }
        }
    }
}

extension Collection where Element: Hashable {
    /// Retourne l'élément unique s'il est le seul dans la collection, sinon nil
    var uniqueElement: Element? {
        let uniqueValues = Set(self)
        return uniqueValues.count == 1 ? uniqueValues.first : nil
    }
}


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

// ⚙️ Extension utilitaire pour extraire un élément unique
extension Collection {
    var uniqueElement: Element? {
        count == 1 ? first : nil
    }
}

// 🧩 Vue principale unifiée pour édition normale ou groupée
struct TransactionFormUnifiedView: View {
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    @EnvironmentObject var formState: TransactionFormState

    var body: some View {
        if transactionManager.selectedTransactions.count > 1 {
            let uniqueStatus = transactionManager.selectedTransactions.compactMap { $0.status }.uniqueElement
            let uniqueMode = transactionManager.selectedTransactions.compactMap { $0.paymentMode }.uniqueElement
            let uniqueDate = transactionManager.selectedTransactions.map { $0.dateOperation }.uniqueElement
            let uniquePointingDate = transactionManager.selectedTransactions.map { $0.datePointage }.uniqueElement
            let uniqueBankStatement = transactionManager.selectedTransactions.map { $0.bankStatement }.uniqueElement.map { String($0) }

            TransactionFormView(
                overrideTransactionDate: uniqueDate,
                overridePointingDate: uniquePointingDate,
                overrideStatus: uniqueStatus,
                overrideMode: uniqueMode,
                overrideBankStatement: uniqueBankStatement
            )
        } else {
            TransactionFormView()
        }
    }
}

// 📋 Vue d'entrée pour appeler TransactionFormViewModel avec ou sans override
struct TransactionFormView: View {
    @EnvironmentObject var formState: TransactionFormState
    
    var overrideTransactionDate: Date? = nil
    var overridePointingDate: Date? = nil
    var overrideStatus: EntityStatus? = nil
    var overrideMode: EntityPaymentMode? = nil
    var overrideBankStatement: String? = nil
    
    var body: some View {
        if $formState.accounts.count == 0 {
            EmptyView()
        } else {
            TransactionFormViewModel(
                linkedAccount           : $formState.accounts,
                transactionDate         : $formState.transactionDate,
                pointingDate            : $formState.pointingDate,
                modes                   : $formState.paymentModes,
                status                  : $formState.status,
                bankStatement           : $formState.bankStatement,
                checkNumber             : $formState.checkNumber,
                amount                  : $formState.amount,
                selectedBankStatement   : $formState.selectedBankStatement,
                selectedStatus          : $formState.selectedStatus,
                selectedMode            : $formState.selectedMode,
                selectedAccount         : $formState.selectedAccount,
                overrideTransactionDate : overrideTransactionDate,
                overridePointingDate    : overridePointingDate,
                overrideStatus          : overrideStatus,
                overrideMode            : overrideMode,
                overrideBankStatement   : overrideBankStatement
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Transaction form section"))
        }
    }
}

//  OperationDialog3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

//✅ Résultat
//    •    🔶 Mode Création → titre orange
//    •    🔵 Édition d’une transaction → bleu
//    •    🟣 Édition multiple → violet

import SwiftUI
import AppKit
import SwiftData


// MARK: - TransactionFormViewModel
struct TransactionFormViewModel: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    @Binding var linkedAccount: [EntityAccount]
    
    @Binding var transactionDate : Date
    @Binding var pointingDate    : Date
    
    @Binding var modes: [EntityPaymentMode]
    @Binding var status: [EntityStatus]
    @Binding var bankStatement: Double
    @Binding var checkNumber: Int
    @Binding var amount: String
    
    @State private var entityPreference : EntityPreference?
    
    @Binding var selectedBankStatement: String
    @Binding var selectedStatus: EntityStatus?
    @Binding var selectedMode: EntityPaymentMode?
    @Binding var selectedAccount : EntityAccount?
//    @State private var selectedAccount: EntityAccount? = nil

    // 🔁 Valeurs de remplacement pour édition multiple (batch)
    var overrideTransactionDate: Date? = nil
    var overridePointingDate: Date? = nil
    var overrideStatus: EntityStatus? = nil
    var overrideMode: EntityPaymentMode? = nil
    var overrideBankStatement: String? = nil
    
    @State private var selectedOperations: Set<EntityTransaction> = []
    
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    
    private var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
    var isEditing: Bool {
        selectedOperations.count > 0
    }
    
    private var identitySection: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
            GridRow {
                FormField(label: "Linked Account") {
                    
                    Picker("", selection: $selectedAccount) {
                        // Option "aucun compte sélectionné"
                        Text(String(localized: "(no account)"))
                            .tag(nil as EntityAccount?)  // 👈 corrige l'erreur
                        
                        // Autres comptes
                        ForEach(linkedAccount, id: \.uuid) { account in
                            let isCurrent = compteCurrent == account
                            Text(isCurrent ? String(localized: "(no transfer)") :
                                    (account.initAccount?.codeAccount ?? ""))
                            .tag(account as EntityAccount?) // 👈 obligatoire ici aussi
                        }
                    }
                }
            }
            GridRow {
                FormField(label: String(localized:"Account")) {
                    Text(selectedAccount?.name ?? "")
                }
            }
            GridRow {
                FormField(label: String(localized:"Name")) {
                    Text(selectedAccount?.identity?.name ?? "")
                }
            }
            GridRow {
                FormField(label: String(localized:"Surname")){
                    Text(selectedAccount?.identity?.surName ?? "")
                }
            }
        }
    }
    private var detailSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
            GridRow {
                FormField(label: String(localized:"Transaction Date")) {
                    DatePicker("", selection: $transactionDate, displayedComponents: .date)
                }
                .disabled(transactionManager.selectedTransactions.count > 1)
            }
            GridRow {
                FormField(label: String(localized:"Payment method")) {
                    Picker("", selection: $selectedMode) {
                        ForEach(modes, id: \.uuid) { mode in
                            Text(mode.name).tag(mode)
                        }
                    }
                }
            }
            GridRow {
                FormField(label: String(localized:"Check")) {
                    TextField("", value: $checkNumber, formatter: integerFormatter)
                }
            }
            GridRow {
                FormField(label: String(localized:"Date of pointing")) {
                    DatePicker("", selection: $pointingDate, displayedComponents: .date)
                }
                .disabled(transactionManager.selectedTransactions.count > 1)
            }
            GridRow {
                FormField(label: String(localized:"Status")) {
                    Picker("", selection: $selectedStatus) {
                        ForEach(status, id: \.self) { index in
                            Text(index.name).tag(index)
                        }
                    }
                    HelpButton {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• **Planned**: estimated check-in date, amount subject to changee")
                            Text("• **Committed**: estimated check-in date, modifiable amount")
                            Text("• **Pointed**: exact date of the statement, amount not modifiable")
                            Divider()
                            Text("💡 **Keyboard shortcuts**: P = Planned, E = Committed, T = Pointed")
                        }
                        .font(.system(size: 12))
                        .padding(8)
                    }

                }
            }
            GridRow {
                FormField(label: String(localized:"Bank Statement")) {
                    TextField("", value: $bankStatement, formatter: integerFormatter)
                }
            }
            GridRow {
                FormField(label: String(localized:"Amount")) {
                    TextField("", value: $amount, formatter: NumberFormatter())
                }
            }
        }
    }
    
    private func handleKey(_ event: NSEvent) {
        guard let character = event.charactersIgnoringModifiers?.uppercased() else { return }

        switch character {
        case "P":
            if let prévu = status.first(where: { $0.name.hasPrefix("Prévu") }) {
                selectedStatus = prévu
            }
        case "E":
            if let engagé = status.first(where: { $0.name.hasPrefix("Engagé") }) {
                selectedStatus = engagé
            }
        case "T":
            if let pointé = status.first(where: { $0.name.hasPrefix("Pointé") }) {
                selectedStatus = pointé
            }
        default:
            break
        }
    }
    
    var body: some View {

        Form {
            Section {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                    GridRow {
                        Text("Informations")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GridRow {
                        identitySection
                    }
                }
            }

            HStack {
                Spacer()
                Text("⋯")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            Section {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                    GridRow {
                        Text("Details of the operation")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GridRow {
                        detailSection
                    }
                }
            }
            .onAppear {
                            
                selectedAccount = linkedAccount.first(where: { $0.uuid == selectedAccount?.uuid })
                if selectedAccount == nil {
                    selectedAccount = nil // Pour que le Picker reconnaisse l'état initial
                }

                let account = CurrentAccountManager.shared.getAccount()
                guard let account = account else { return }
                if let oldSelected = selectedAccount {
                    selectedAccount = linkedAccount.first(where: { $0.uuid == oldSelected.uuid })
                }

                entityPreference = PreferenceManager.shared.getAllData(for: account)
                
                //            if selectedAccount == nil, let firstAccount = linkedAccount.first {
                //                selectedAccount = firstAccount // Initialisation avec un compte valide
                //            }
                
                if selectedAccount == nil {
                    selectedAccount = linkedAccount.first ?? compteCurrent
                }
                
                DispatchQueue.main.async {
                    selectedMode = modes.first
                    selectedMode = entityPreference?.paymentMode
                    selectedStatus = entityPreference?.status
                    selectedBankStatement = ""
                }
            }
            .onChange(of: selectedAccount) { old, newValue in
//                printTag("Selected Account: \(newValue?.name ?? "nil")")
            }
            .onChange(of: selectedMode) { old, newValue in
                printTag("Selected Mode: \(newValue?.name ?? "nil")")
            }
            .onChange(of: selectedStatus) { old, newValue in
                printTag("Selected Status: \(newValue?.name ?? "nil")")
            }
            .onChange(of: compteCurrent) {old, new in
                selectedAccount = compteCurrent
            }
            
            .onChange(of: linkedAccount) { old, newValue in
                if let oldSelected = selectedAccount {
                    selectedAccount = newValue.first(where: { $0.uuid == oldSelected.uuid })
                }
                return
            }
            .onChange(of: selectedAccount) { oldValue, newValue in
            }
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .bold()
                .frame(width: 120, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//
//  OperationDialog4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 09/03/2025.
//


import SwiftUI
import AppKit
import SwiftData
import Observation
import Combine

@MainActor
final class TransactionFormState: ObservableObject {
    // 🧾 Données principales du formulaire
    @Published var accounts: [EntityAccount] = []
    @Published var transactionDate: Date = Date().noon
    @Published var pointingDate: Date = Date().noon
    @Published var paymentModes: [EntityPaymentMode] = []
    @Published var status: [EntityStatus] = []
    @Published var bankStatement: Double = 0.0
    @Published var checkNumber: Int = 0
    @Published var amount: String = ""

    @Published var selectedBankStatement: String = ""
    @Published var selectedStatus: EntityStatus? = nil
    @Published var selectedMode: EntityPaymentMode? = nil
    @Published var selectedAccount: EntityAccount? = nil

    // 🔁 Indicateur de mode édition groupée (batch editing)
    @Published var isBatchEditing: Bool = false

    // 🧩 Valeurs uniques extraites automatiquement lors d’un batch edit
    @Published var batchUniqueTransactionDate: Date? = nil
    @Published var batchUniquePointingDate: Date? = nil
    @Published var batchUniqueStatus: EntityStatus? = nil
    @Published var batchUniqueMode: EntityPaymentMode? = nil
    @Published var batchUniqueBankStatement: String? = nil
    
    @Published var subOperations: [EntitySousOperation] = []
    @Published var currentSousTransaction: EntitySousOperation? = nil
    @Published var isShowingDialog: Bool = false
    
    @Published var currentTransaction: EntityTransaction? = nil
    @Published var entityTransactions: [EntityTransaction] = []


    // 📥 Méthode pour charger des valeurs batch depuis les transactions sélectionnées
    func updateBatchValues(from transactions: [EntityTransaction]) {
        isBatchEditing = transactions.count > 1

        batchUniqueTransactionDate = transactions.map { $0.dateOperation }.uniqueElement
        batchUniquePointingDate = transactions.map { $0.datePointage }.uniqueElement
        batchUniqueStatus = transactions.compactMap { $0.status }.uniqueElement
        batchUniqueMode = transactions.compactMap { $0.paymentMode }.uniqueElement
        batchUniqueBankStatement = transactions.map { $0.bankStatement }.uniqueElement.map { String($0) }
    }

    // 🔄 Réinitialisation complète
    func reset() {
        isBatchEditing = false
        batchUniqueTransactionDate = nil
        batchUniquePointingDate = nil
        batchUniqueStatus = nil
        batchUniqueMode = nil
        batchUniqueBankStatement = nil

        transactionDate = Date().noon
        pointingDate = Date().noon
        checkNumber = 0
        bankStatement = 0.0
        amount = ""
        selectedBankStatement = ""
        selectedStatus = nil
        selectedMode = nil
        selectedAccount = nil
    }
}




