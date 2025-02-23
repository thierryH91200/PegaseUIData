

import SwiftUI
import AppKit
import SwiftData

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
    @Binding var amount: String
    
    @Binding var selectedBankStatement: String?
    @Binding var selectedStatut: String
    @State var selectedMode: EntityPaymentMode?
    @State var selectAccount : EntityAccount?
    
    var CompteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormField(label: String(localized: "Linked Account")) {
                Picker("", selection: $selectAccount) {
                    ForEach(linkedAccount, id: \.uuid) { account in
                        if account == CompteCurrent {
                            Text("(no transfer)").tag(nil as EntityAccount?)
                        } else {
                            Text(account.initAccount?.codeAccount ?? "").tag(account)
                        }
                    }
                }
            }
            
            FormField(label: String(localized: "Comment")) {
                Text( selectAccount?.name ?? "")
            }
            
            FormField(label: String(localized: "Name")) {
                Text( selectAccount?.identity?.name ?? "")
            }
            
            FormField(label: String(localized: "Surname")) {
                Text( selectAccount?.identity?.surName ?? "")
            }
            
            Divider()
            
            FormField(label: String(localized: "Date Transaction")) {
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
            }
            
            FormField(label: String(localized: "Payment method")) {
                Picker("", selection: $selectedMode) {
                    ForEach(modes, id: \.self) { mode in
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
                TextField("", value: $bankStatement, formatter: NumberFormatter())
            }
            
            FormField(label: String(localized:"Amount")) {
                TextField("", value: $amount, formatter: NumberFormatter())
            }

            
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
