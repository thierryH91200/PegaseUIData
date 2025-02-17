

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
struct OperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @State private var isEditDialogPresented = false
    @State private var isAddDialogPresented = false
    @State private var modeCreate = false

    
    @ObservedObject var paymentModeManager = ModeManager()
    @ObservedObject var rubricManager = RubriqueManager()

    @State private var entityAccounts : [EntityAccount]
    var entityRubric : [EntityRubric]?
    var entityCategorie : [EntityCategory]?
    
    @State private var linkedAccount = " "
    @State private var comment = " "
    @State private var name = " "
    @State private var surname = " "
    
    @State private var transactionDate = Date()
    @State private var entityPaymentMode : [EntityPaymentMode] = []

    @State private var pointingDate = Date()
    @State private var statut : [String] = [String(localized :"Planned"),
                                            String(localized :"Engaged"),
                                            String(localized :"Executed")]
    @State private var bankStatement = 0
    
    @State private var amount = ""
    
    @State private var selectedBankStatement: String?
    @State private var selectedStatut = String(localized :"Engaged")
    @State private var selectedMode : EntityPaymentMode?
    @State private var selectedAccount : EntityAccount?

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(modeCreation: Bool) {
        self.modeCreate = modeCreation
//        selectedAccount = CurrentAccountManager.shared.getAccount()
        entityAccounts =  []
    }
    
    var body: some View {
        
        ZStack { // Permet de positionner la boîte de dialogue à droite
            Color(NSColor.windowBackgroundColor) // Fond de fenêtre
            
            VStack(spacing: 0) {
                // Titre en haut
                Text("\(modeCreate ? String(localized:"Create") : String(localized:"Edit"))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                
                // Contenu principal
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        Divider()
                        
                        // Sub-operation Section
                        SubOperationView()
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .padding([.leading, .trailing])
                        
                        Spacer()
                    }
                    .padding()
                }
                
                // Boutons bas
                HStack {
                    Button("Cancel", action: {
                        
                    })
                    Spacer()
                    Button("OK", action: {
                        
                    })
                        .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            // Feuilles modales pour l'ajout/modification
            .sheet(isPresented: $isEditDialogPresented) {
                SousOperationFormView(isPresented: $isEditDialogPresented, mode: $modeCreate)
            }
            .sheet(isPresented: $isAddDialogPresented) {
                SousOperationFormView(isPresented: $isAddDialogPresented, mode: $modeCreate)
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
            .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .shadow(radius: 5) // Ajout d'une ombre pour l'esthétique
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Étendre la vue sur toute la fenêtre
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormField(label: String(localized: "Linked Account")) {
                Picker("", selection: $selectAccount) {
                    Text("(no transfer)").tag(nil as EntityAccount?)
                    ForEach(linkedAccount, id: \.uuid) { account in
                        Text(account.initAccount?.codeAccount ?? "").tag(account)
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

// MARK: - SousOperationFormView
struct SousOperationFormView: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var mode: Bool

    
    @State var rubric : [String] = []
    @State var categorie : [String] = []
    @State var comment : String = ""
    @State var amount : String = ""
    
    @State private var entityPreference : EntityPreference?
    @State private var entityRubric : [EntityRubric]?
    @State private var entityCategorie : [EntityCategory]?
    
    @State private var selectedRubric : String = ""
    @State private var selectedCategorie : String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Ligne 1 : Comment
            
            FormField(label: "Comment") {
                TextField("", text: $comment)
            }
            
            FormField(label: "Rubric") {
                Picker("", selection: $selectedRubric) {
                    ForEach(rubric, id: \.self) { rubricItem in
                        Text(rubricItem).tag(rubricItem)
                    }
                }
            }
            
            FormField(label: "Category") {
                Picker("", selection: $selectedCategorie) {
                    ForEach(categorie, id: \.self) { categoryItem in
                        Text(categoryItem).tag(categoryItem)
                    }
                }
            }
            
            FormField(label: "Amount") {
                TextField("", text: $amount)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isPresented = false
                        save()
                        dismiss()
                    }
                }
            }
        }
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
                rubric = entityRubric?.map { $0.name } ?? []
                
                if let preference = entityPreference, let rubricIndex = entityRubric?.firstIndex(where: { $0 == preference.category?.rubric }) {
                    selectedRubric = rubric[rubricIndex]
                    let entityCategory = entityRubric![rubricIndex].categorie.sorted { $0.name < $1.name }
                    categorie = entityCategory.map { $0.name }
                    if let categoryIndex = entityCategory.firstIndex(where: { $0 === preference.category }) {
                        selectedCategorie = categorie[categoryIndex]
                    }
                }
            } catch {
                print("Failed to configure form: \(error)")
            }
        }
    }
    
    
    func save() {
        
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
                .frame(width: 200)
        }
    }
}
