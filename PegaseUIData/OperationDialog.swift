

import SwiftUI
import AppKit
import SwiftData

// MARK: - OperationDialog
struct OperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false

    let modeCreate : Bool

    var statut = [String(localized :"Plannifie"),
                  String(localized :"Engaged"),
                  String(localized :"Executed")]
    
    @State var rub : [String] = []
    @State var categorie : [String] = []
    @State private var modes : [String] = []

    var entityRubric : [EntityRubric]?
    var entityCategorie : [EntityCategory]?
    @State private var entityPaymentMode : [EntityPaymentMode]? = []


    @State private var linkedAccount = " "
    @State private var comment = " "
    @State private var name = " "
    @State private var surname = " "
    @State private var transactionDate = Date()
    @State private var pointingDate = Date()
    @State private var number = ""
    @State private var bankStatement = 0
    @State private var amount = " "
    
    @State private var selectedBankStatement: String?
    @State private var selectedStatut = String(localized :"Engaged")
    @State private var selectedMode = String(localized :"Bank Card")

    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(modeCreation: Bool) {
        self.modeCreate = modeCreation
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
                        
                        TransactionFormViewModel()
                        
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
                    Button("Cancel", action: {})
                    Spacer()
                    Button("OK", action: {})
                        .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            // Feuilles modales pour l'ajout/modification
            .sheet(isPresented: $isEditDialogPresented) {
//                SousOperationFormView(isPresented: $isEditDialogPresented)
            }
            .sheet(isPresented: $isAddDialogPresented) {
//                SousOperationFormView(isPresented: $isAddDialogPresented)
            }
            .onAppear {
                Task {
                    PaymentModeManager.shared.configure(with: modelContext)
                    if let account = CurrentAccountManager.shared.getAccount() {
                        
                        entityPaymentMode = PaymentModeManager.shared.getAllDatas(for: account) ?? []
                    }

                }
            }
            .frame(minWidth: 200, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .shadow(radius: 5) // Ajout d'une ombre pour l'esthétique
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Étendre la vue sur toute la fenêtre
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
            
            Text("No chart Data available.")
                .font(.footnote)
        }
    }
    
    func delete () {
    }

}

// MARK: - TransactionFormViewModel
struct TransactionFormViewModel : View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var linkedAccount = " "
    @State private var comment = " "
    @State private var name = " "
    @State private var surname = " "
    @State private var transactionDate = Date()
    @State private var pointingDate = Date()
    @State private var number = ""
    @State private var bankStatement = 0
    @State private var amount = " "
    
    @State private var selectedBankStatement: String?
    @State private var selectedStatut = String(localized :"Engaged")
    @State private var selectedMode = String(localized :"Bank Card")
    
    var body: some View {
        
            // Ligne 1 : Compte lié
            HStack {
                Text("Linked Account")
                Spacer()
                Picker("", selection: .constant("")) {
                    Text("(no transfer)").tag("")
                }
                .frame(width: 200)
            }
            
            Divider()
            
            // Ligne 2 : Intitulé
            HStack {
                Text("Comment")
                Spacer()
                TextField("", text: $comment)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            // Ligne 3 : Nom et Prénom
            HStack {
                Text("Name")
                Spacer()
                TextField("", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            HStack {
                Text("Surname")
                Spacer()
                TextField("", text: $surname)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            Divider()
            
            // Ligne 4 : Date Transaction et Mode
            HStack {
                Text("Date Transaction")
                Spacer()
                DatePicker("", selection: $transactionDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(width: 200)
            }
            
            HStack {
                Text("Mode")
                Spacer()
                Picker("", selection: $selectedMode) {
//                    ForEach(modes, id: \.self) { mode in
//                        Text(mode).tag(mode)
//                    }
                }
                .frame(width: 200)
            }
            
            Divider()
            
            // Ligne 5 : Date Pointage et Statut
            HStack {
                Text("Date of pointing")
                Spacer()
                DatePicker("", selection: $pointingDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(width: 200)
            }
            
            HStack {
                Text("Statut")
                Spacer()
                Picker("", selection: $selectedStatut) {
//                    ForEach(statut, id: \.self) {
//                        Text($0).tag($0)
//                    }
                }
                .frame(width: 200)
            }
            Divider()
    }
}


// MARK: - SousOperationFormView
struct SousOperationFormView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool

    @State var rubric : [String] = []
    @State var categorie : [String] = []
    @State var comment : String = ""
    @State var amount : String = ""

    @State private var entityPreference : EntityPreference?
    @State private var entityRubric : [EntityRubric]?
    @State private var entityCategorie : [EntityCategory]?

    @State private var selectedRubric : String
    @State private var selectedCategorie : String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Ligne 1 : Comment
            HStack {
                Text("Comment")
                Spacer()
                TextField("", text: $comment)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            Divider()
            HStack {
                Text("Rubric")
                Spacer()
                Picker("", selection: $selectedRubric) {
                    ForEach(rubric, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .frame(width: 200)
            }
            Divider()

            HStack {
                Text("Category")
                Spacer()
                Picker("", selection: $selectedCategorie) {
                    ForEach(categorie, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .frame(width: 200)
            }
            
            Divider()
            HStack {
                Text("Amount")
                Spacer()
                TextField("", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
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
                
                RubricManager.shared.configure(with: modelContext)
                PreferenceManager.shared.configure(with: modelContext)
                PaymentModeManager.shared.configure(with: modelContext)

                let account = CurrentAccountManager.shared.getAccount()
                self.entityPreference = PreferenceManager.shared.getAllDatas(for: account)
                
                /// Rubrique
                RubricManager.shared.configure(with: modelContext)
                self.entityRubric = RubricManager.shared.getAllDatas()
                rubric = (0..<entityRubric!.count).map { i -> String in
                    return entityRubric![i].name
                }
                var i = entityRubric!.firstIndex { $0 == entityPreference?.category?.rubric }
                selectedRubric = rubric [ i!]

                /// Category
                var entityCategory = entityRubric![i!].categorie
                entityCategory = entityCategory.sorted { $0.name < $1.name }
                
                i = entityCategory.firstIndex { $0 === entityPreference?.category }
//                selectedRubric = selectItem(at: i!)
                
                print(rubric)
         }
    }
    
    func save() {
        
    }


}
