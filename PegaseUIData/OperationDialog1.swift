

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
    @Binding var linkedAccount: [EntityAccount]
    
    @Binding var transactionDate: Date
    @Binding var modes: [EntityPaymentMode]
    @Binding var pointingDate: Date
    @Binding var statut: [String]
    @Binding var bankStatement: Int
    @Binding var checkNumber: Int
    @Binding var amount: String
    
    @Binding var selectedBankStatement: String
    @Binding var selectedStatut: String
    @Binding var selectedMode: EntityPaymentMode?
    @Binding var selectedAccount : EntityAccount?
    
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    
//    @State private var CurrentAccountManager.shared
    
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
            
            FormField(label: String(localized: "Date Transaction")) {
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
            }
            
            FormField(label: String(localized: "Payment method")) {
                Picker("", selection: $selectedMode) {
                    ForEach(modes, id: \.uuid) { mode in
                        Text(mode.name).tag(mode)
                    }
                }
            }
            
            FormField(label: String(localized: "Date of pointing")) {
                DatePicker("", selection: $pointingDate, displayedComponents: .date)
            }
            
            FormField(label: String(localized: "Statut")) {
                Picker("", selection: $selectedStatut) {
                    ForEach(statut, id: \.self) {
                        Text($0).tag($0)
                    }
                }
            }
            
            FormField(label: String(localized:"Bank statement")) {
                TextField("", value: $bankStatement, formatter: integerFormatter)
            }

            FormField(label: String(localized:"Check")) {
                TextField("", value: $checkNumber, formatter: integerFormatter)
            }

            FormField(label: String(localized:"Amount")) {
                TextField("", value: $amount, formatter: NumberFormatter())
            }
        }
        .onAppear {
            selectedAccount = compteCurrent
            if let firstMode = modes.first {
                selectedMode = firstMode
            }
            if statut.indices.contains(1) {
                selectedStatut = statut[1]
            }
            selectedBankStatement = ""
        }
        .onChange(of: compteCurrent) {old, new in
            selectedAccount = compteCurrent
        }

        .onChange(of: linkedAccount) { old, newValue in
            print("linkedAccount mis à jour : \(newValue.map { $0.name })")
            if !newValue.contains(where: { $0 == selectedAccount }) {
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
