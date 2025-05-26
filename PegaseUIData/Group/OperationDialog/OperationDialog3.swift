//  OperationDialog2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//


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

    @Binding var linkedAccount: [EntityAccount]
    
    @Binding var transactionDate: Date
    @Binding var modes: [EntityPaymentMode]
    @Binding var pointingDate: Date
    @Binding var status: [EntityStatus]
    @Binding var bankStatement: Double
    @Binding var checkNumber: Int
    @Binding var amount: String
    
    @State private var entityPreference : EntityPreference?
    
    @Binding var selectedBankStatement: String
    @Binding var selectedStatus: EntityStatus?
    @Binding var selectedMode: EntityPaymentMode?
    @Binding var selectedAccount : EntityAccount?
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            FormField(label: String(localized: "Linked Account")) {
                Picker("", selection: $selectedAccount) {
                    ForEach(linkedAccount, id: \.uuid) { account in
                        if let currentAccount = compteCurrent, account == currentAccount {
                            Text(String(localized: "(no transfer)")).tag(account )
                        } else {
                            Text(account.initAccount?.codeAccount ?? "").tag(account)
                        }
                    }
                }
            }
            
            FormField(label: String(localized: "Comment")) {
                Text( selectedAccount?.name ?? "")
            }
            
            FormField(label: String(localized: "Name")) {
                Text( selectedAccount?.identity?.name ?? "")
            }
            
            FormField(label: String(localized: "Surname")) {
                Text( selectedAccount?.identity?.surName ?? "")
            }
            
            Divider()
            
            FormField(label: String(localized: "Transaction Date")) {
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
            }
            
            FormField(label: String(localized: "Payment method")) {
                Picker("", selection: $selectedMode) {
                    ForEach(modes, id: \.uuid) { mode in
                        Text(mode.name).tag(mode)
                    }
                }
            }
            
            FormField(label: String(localized:"Check")) {
                TextField("", value: $checkNumber, formatter: integerFormatter)
            }

            FormField(label: String(localized: "Date of pointing")) {
                DatePicker("", selection: $pointingDate, displayedComponents: .date)
            }
            
            FormField(label: String(localized: "Status")) {
                Picker("", selection: $selectedStatus) {
                    ForEach(status, id: \.self) { index in
                        Text(index.name).tag(index)
                    }
                }
            }
            
            FormField(label: String(localized:"Bank Statement")) {
                TextField("", value: $bankStatement, formatter: integerFormatter)
            }

            FormField(label: String(localized:"Amount")) {
                TextField("", value: $amount, formatter: NumberFormatter())
            }
        }
        .onAppear {
            PreferenceManager.shared.configure(with: modelContext)
            let account = CurrentAccountManager.shared.getAccount()
            self.entityPreference = PreferenceManager.shared.getAllData(for: account)

            if selectedAccount == nil, let firstAccount = linkedAccount.first {
                selectedAccount = firstAccount // Initialisation avec un compte valide
            }
            DispatchQueue.main.async {
                selectedMode = modes.first
                selectedMode = entityPreference?.paymentMode
                selectedStatus = entityPreference?.status
                selectedBankStatement = ""
            }
        }
        .onChange(of: selectedAccount) { old, newValue in
            print("Selected Account: \(newValue?.name ?? "nil")")
        }
        .onChange(of: selectedMode) { old, newValue in
            print("Selected Mode: \(newValue?.name ?? "nil")")
        }
        .onChange(of: selectedStatus) { old, newValue in
            print("Selected Status: \(newValue?.name ?? "nil")")
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
            print("Compte sélectionné mis à jour : \(newValue?.name ?? "nil")")
        }
    }
}

// MARK: - FormField
struct FormField<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            content
                .frame(width: 200, alignment: .leading)
        }
    }
}
