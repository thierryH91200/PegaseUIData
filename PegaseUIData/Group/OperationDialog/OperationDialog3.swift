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

// MARK: - Managers
// PaymentModeManager et RubricManager comme ObservableObject
class ModeManager: ObservableObject {
    @Published var names: [String] = []
    @Published var paymentModes: [EntityPaymentMode] = []
}

class RubriqueManager: ObservableObject {
    @Published var rubrics: [String] = []
}

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
    
    private var modeBanner: some View {
        switch transactionManager.formMode {
        case .create:
            return Text("Creation")
        case .editSingle:
            return Text("Edit a transaction")
        case .editMultiple(let ops):
            return Text("Edit to \(ops.count) transactions")
        }
    }
    private var identitySection: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
            GridRow {
                FormField(label: "Linked Account") {
                    Picker("", selection: $selectedAccount) {
                        ForEach(linkedAccount, id: \.uuid) { account in
                            let isCurrent = compteCurrent == account
                            Text(isCurrent ? String(localized: "(no transfer)") :
                                             (account.initAccount?.codeAccount ?? ""))
                                .tag(account)
                        }
                    }
                }
            }
            GridRow {
                FormField(label: "Account") {
                    Text(selectedAccount?.name ?? "")
                }
            }
            GridRow {
                FormField(label: "Name") {
                    Text(selectedAccount?.identity?.name ?? "")
                }
            }
            GridRow {
                FormField(label: "Surname") {
                    Text(selectedAccount?.identity?.surName ?? "")
                }
            }
        }
    }
    private var detailSection: some View {
        Group {
            FormField(label: "Transaction Date") {
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
            }

            FormField(label: "Payment method") {
                Picker("", selection: $selectedMode) {
                    ForEach(modes, id: \.uuid) { mode in
                        Text(mode.name).tag(mode)
                    }
                }
            }

            FormField(label: "Check") {
                TextField("", value: $checkNumber, formatter: integerFormatter)
            }

            FormField(label: "Date of pointing") {
                DatePicker("", selection: $pointingDate, displayedComponents: .date)
            }

            FormField(label: "Status") {
                Picker("", selection: $selectedStatus) {
                    ForEach(status, id: \.self) { index in
                        Text(index.name).tag(index)
                    }
                }
            }

            FormField(label: "Bank Statement") {
                TextField("", value: $bankStatement, formatter: integerFormatter)
            }

            FormField(label: "Amount") {
                TextField("", value: $amount, formatter: NumberFormatter())
            }
        }
    }
    
    var body: some View {
        FormTitleView(formMode: transactionManager.formMode)

        Form {
            modeBanner
            Section {
                Section(header:
                    Text("Informations")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                ) {
                    identitySection
                }

                Section(header:
                    Text("Details of the operation")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                ) {
                    detailSection
                }
            }
            .onAppear {
                DataContext.shared.context = modelContext
                let account = CurrentAccountManager.shared.getAccount()
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
                printTag("Selected Account: \(newValue?.name ?? "nil")")
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
                if !newValue.contains( selectedAccount! ) {
                    selectedAccount = newValue.first
                }
            }
            .onChange(of: selectedAccount) { oldValue, newValue in
                printTag("Compte sélectionné mis à jour : \(newValue?.name ?? "nil")")
            }
        }
    }
    
    
    func load(from operation: EntityTransaction) {
        transactionDate = operation.dateOperation
        pointingDate = operation.datePointage
        bankStatement = operation.bankStatement
        checkNumber = Int(operation.checkNumber)!
        amount = String(operation.amount)
        selectedStatus = operation.status
        selectedMode = operation.paymentMode
        selectedAccount = operation.account
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
                .frame(width: 120, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FormTitleView: View {
    let formMode: FormMode

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(8)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var title: String {
        switch formMode {
        case .create:
            return String(localized:"Mode Creation")
        case .editSingle:
            return String(localized:"Mode Edit")
        case .editMultiple(let ops):
            return String(localized:"Edition multiple (\(ops.count)) transactions")
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

