

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

// MARK: - OperationDialog
//struct  TransactionView: View {
//    
//    @Environment(\.modelContext) private var modelContext: ModelContext
//    
//    @State private var isEditDialogPresented = false
//    @State private var isAddDialogPresented = false
//    @State private var modeCreate = false
//    
//
//    @ObservedObject var paymentModeManager = ModeManager()
//    @ObservedObject var rubricManager = RubriqueManager()
//    
//    @State private var entityAccounts : [EntityAccount]
//    var entityRubric : [EntityRubric]?
//    var entityCategorie : [EntityCategory]?
//    
//    @State private var linkedAccount = " "
//    @State private var comment = " "
//    @State private var name = " "
//    @State private var surname = " "
//    
//    @State private var transactionDate = Date()
//    @State private var entityPaymentMode : [EntityPaymentMode] = []
//    
//    @State private var pointingDate = Date()
//    @State private var statut : [String] = [String(localized :"Planned"),
//                                            String(localized :"Engaged"),
//                                            String(localized :"Executed")]
//    @State private var bankStatement = 0
//    
//    @State private var amount = ""
//    
//    @State private var selectedBankStatement: String?
//    @State private var selectedStatut = String(localized :"Engaged")
//    @State private var selectedMode : EntityPaymentMode?
//    @State private var selectedAccount : EntityAccount?
//    
//    @State private var subOperations: [SubOperation] = [SubOperation(comment: "Supermarket", amount: "75,00 €")]
//    @State private var newSubOperationName: String = ""
//    @State private var newSubOperationAmount: String = ""
//    
//    
//    
//    let numberFormatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        return formatter
//    }()
//    
//    init(modeCreation: Bool) {
//        self.modeCreate = modeCreation
//        //        selectedAccount = CurrentAccountManager.shared.getAccount()
//        entityAccounts =  []
//    }
//    
//    var body: some View {
//        
//        ZStack { // Permet de positionner la boîte de dialogue à droite
//            Color(NSColor.windowBackgroundColor) // Fond de fenêtre
//            
//            VStack(spacing: 0) {
//                // Titre en haut
//                Text("\(modeCreate ? String(localized:"Create") : String(localized:"Edit"))")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.green)
//                
//                // Contenu principal
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 16) {
//                        if selectedAccount != nil {
//                            TransactionFormViewModel(
//                                linkedAccount: $entityAccounts,
//                                transactionDate: $transactionDate,
//                                modes: $entityPaymentMode,
//                                pointingDate: $pointingDate,
//                                statut: $statut,
//                                bankStatement: $bankStatement,
//                                amount: $amount,
//                                selectedBankStatement: $selectedBankStatement,
//                                selectedStatut: $selectedStatut,
//                                selectedMode: selectedMode,
//                                selectAccount: selectedAccount
//                            )
//                        }
//                        
//                        Divider()
//                        
//                        // Sub-operation Section
//                        SubOperationView()
//                            .frame(maxWidth: .infinity, maxHeight: 100)
//                            .padding([.leading, .trailing])
//                        
//                        Spacer()
//                    }
//                    .padding()
//                }
//                
//                Text("Split Transactions")
//                    .font(.headline)
//                
//                List {
//                    ForEach(subOperations) { subOperation in
//                        HStack {
//                            Text(subOperation.comment)
//                            Spacer()
//                            Text(subOperation.amount)
//                                .foregroundColor(.red)
//                            Spacer().frame(width: 20)
//                            Button(action: {
//                                // Edit action
//                            }) {
//                                Image(systemName: "pencil")
//                            }
//                            Button(action: {
//                                if let index = subOperations.firstIndex(where: { $0.id == subOperation.id }) {
//                                    subOperations.remove(at: index)
//                                }
//                            }) {
//                                Image(systemName: "trash")
//                            }
//                        }
//                    }
//                }
//                
//                HStack {
//                    TextField("New Sub-operation Name", text: $newSubOperationName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                    TextField("Amount", text: $newSubOperationAmount)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .frame(width: 100)
//                    
//                    Button(action: {
//                        let newSubOperation = SubOperation(comment: newSubOperationName, amount: newSubOperationAmount)
//                        subOperations.append(newSubOperation)
//                        newSubOperationName = ""
//                        newSubOperationAmount = ""
//                    }) {
//                        Image(systemName: "plus")
//                    }
//                    .padding(.leading)
//                }
//                
//                
//                
//                // Boutons bas
//                HStack {
//                    Button(action: {
//                        // Cancel action
//                    }) {
//                        Text("Cancel")
//                            .frame(width: 100)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.gray)
//                            .cornerRadius(5)
//                    }
//                    
//                    Button(action: {
//                        // OK action
//                    }) {
//                        Text("OK")
//                            .frame(width: 100)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.green)
//                            .cornerRadius(5)
//                    }
//                }
//                .padding()
//            }
//            
//            // Feuilles modales pour l'ajout/modification
//            .sheet(isPresented: $isEditDialogPresented) {
//                SousOperationFormView(isPresented: $isEditDialogPresented, mode: $modeCreate)
//            }
//            .sheet(isPresented: $isAddDialogPresented) {
//                SousOperationFormView(isPresented: $isAddDialogPresented, mode: $modeCreate)
//            }
//            .onAppear {
//                Task {
//                    do {
//                        try await configurePaymentModes()
//                    } catch {
//                        print("Failed to configure payment modes: \(error)")
//                    }
//                }
//            }
//            .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
//            .background(Color(NSColor.controlBackgroundColor))
//            .shadow(radius: 5) // Ajout d'une ombre pour l'esthétique
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity) // Étendre la vue sur toute la fenêtre
//    }
//    
//    func configurePaymentModes() async throws {
//        AccountManager.shared.configure(with: modelContext)
//        entityAccounts = AccountManager.shared.getAllData()
//        selectedAccount = CurrentAccountManager.shared.getAccount()
//        
//        PaymentModeManager.shared.configure(with: modelContext)
//        if let account = CurrentAccountManager.shared.getAccount() {
//            entityPaymentMode = PaymentModeManager.shared.getAllDatas(for: account)!
//        }
//    }
//}

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

// MARK: - SubOperationView
struct SubOperationView : View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var modeCreate: Bool = true
    
    
    var body: some View {
        Text("SubOperationView")
        
        VStack {
            Text("Sub-operation")
                .font(.headline)
            
            Text("Add a sub-operation")
                .font(.body)
            
            // Boutons d'action
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    modeCreate = true
                }) {
                    Label("Add", systemImage: "plus")
                        .buttonStyle(.borderedProminent)
                }
                
                Button(action: {
                    isEditDialogPresented = true
                    modeCreate = false
                }) {
                    Label("Edit", systemImage: "pencil")
                        .buttonStyle(.bordered)
                }
                
                Button(
                    action: delete
                ) {
                    Label("Delete", systemImage: "trash")
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
            
            Text("No chart data available.")
                .font(.footnote)
        }
    }
    
    func delete () {
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
