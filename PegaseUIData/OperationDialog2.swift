//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//



import SwiftUI
import AppKit
import SwiftData

struct SubOperation: Identifiable {
    let id = UUID()
    var comment: String
    var rubrique: String = ""
    var category: String = ""
    var amount: String
}

struct OperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext

    @ObservedObject var paymentModeManager = ModeManager()
    @ObservedObject var rubricManager = RubriqueManager()

    @State private var entityAccounts : [EntityAccount]
    var entityRubric : [EntityRubric]?
    var entityCategorie : [EntityCategory]?

    @State private var linkedAccount: String = ""
    @State private var comment = " "
    @State private var name = " "
    @State private var surname = " "

    @State private var transactionDate: Date = Date()
    @State private var entityPaymentMode : [EntityPaymentMode] = []

    @State private var pointingDate: Date = Date()
    @State private var statut : [String] = [String(localized :"Planned"),
                                            String(localized :"Engaged"),
                                            String(localized :"Executed")]

    @State private var amount: String = "75,00 €"
    @State private var subOperations: [SubOperation] = []
    @State private var isShowingDialog: Bool = false
    @State private var currentSubOperation: SubOperation?
    
    @State private var selectedBankStatement: String?
    @State private var selectedStatut = String(localized :"Engaged")
    @State private var selectedMode : EntityPaymentMode?
    @State private var selectedAccount : EntityAccount?
    
    @State private var bankStatement = 0
    @State private var modeCreate = false
    
    init(modeCreation: Bool) {
        self.modeCreate = modeCreation
        //        selectedAccount = CurrentAccountManager.shared.getAccount()
        entityAccounts =  []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Titre en haut
            Text("\(modeCreate ? String(localized:"Create") : String(localized:"Edit"))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
            
            if selectedAccount != nil {
                TransactionFormViewModel(
                    linkedAccount: $entityAccounts,
                    transactionDate: $transactionDate,
                    modes: $entityPaymentMode,
                    pointingDate: $pointingDate,
                    statut: $statut,
                    bankStatement: $bankStatement,
                    amount: $amount,
                    selectedBankStatement: $selectedBankStatement,
                    selectedStatut: $selectedStatut,
                    selectedMode: selectedMode,
                    selectAccount: selectedAccount
                )
            }

            // Split Transactions
            Text(String(localized:"Split Transactions"))
                .font(.headline)

            List {
                ForEach(subOperations) { subOperation in
                    HStack {
                        Text(subOperation.comment)
                        Spacer()
                        Text(subOperation.amount)
                            .foregroundColor(.red)
                        Spacer().frame(width: 20)
                        Button(action: {
                            currentSubOperation = subOperation
                            isShowingDialog = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        Button(action: {
                            if let index = subOperations.firstIndex(where: { $0.id == subOperation.id }) {
                                subOperations.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        try await configurePaymentModes()
                    } catch {
                        print("Failed to configure payment modes: \(error)")
                    }
                }
            }


            HStack {
                Button(action: {
                    currentSubOperation = SubOperation(comment: "", rubrique: "", category: "", amount: "")
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
                    // Cancel action
                }) {
                    Text("Cancel")
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(5)
                }

                Button(action: {
                    // OK action
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
        .sheet(isPresented: $isShowingDialog) {
            SubOperationDialog(subOperation: $currentSubOperation) { updatedSubOperation in
                if let subOperation = updatedSubOperation, let index = subOperations.firstIndex(where: { $0.id == subOperation.id }) {
                    subOperations[index] = subOperation
                } else if let subOperation = updatedSubOperation {
                    subOperations.append(subOperation)
                }
                isShowingDialog = false
            }
        }
    }
    func configurePaymentModes() async throws {
        AccountManager.shared.configure(with: modelContext)
        entityAccounts = AccountManager.shared.getAllData()
        selectedAccount = CurrentAccountManager.shared.getAccount()
        
        PaymentModeManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            entityPaymentMode = PaymentModeManager.shared.getAllDatas(for: account)!
        }
    }
}


struct SubOperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var subOperation: SubOperation?
    var onSave: (SubOperation?) -> Void

    @State private var comment: String = ""
    @State private var rubrique: String = ""
    @State private var category: String = ""
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

            FormField(label: "Rubric") {
                Picker("", selection: $selectedRubric) {
                    ForEach(entityRubric, id: \.self) { rubric in
                        Text(rubric.name).tag(rubric)
                    }
                }
            }

            FormField(label: "Category") {
                Picker("", selection: $selectedCategorie) {
                    ForEach(entityCategorie, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                }
            }

            TextField("Amount", text: $amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button(action: {
                    isShowingDialog = false
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(5)
                }

                Button(action: {
                    if var subOp = subOperation {
                        subOp.comment = comment
                        subOp.rubrique = rubrique
                        subOp.category = category
                        subOp.amount = amount
                        onSave(subOp)
                    } else {
                        let newSubOp = SubOperation(comment: comment, rubrique: rubrique, category: category, amount: amount)
                        onSave(newSubOp)
                    }
                }) {
                    Text("OK")
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
                    let entityCategory = entityRubric[rubricIndex].categorie.sorted { $0.name < $1.name }
                    if let categoryIndex = entityCategory.firstIndex(where: { $0 === preference.category }) {
                        selectedCategorie = entityCategory[categoryIndex]
                    }
                }
            } catch {
                print("Failed to configure form: \(error)")
            }
        }
    }

}

