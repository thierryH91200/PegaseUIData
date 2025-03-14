//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 01/03/2025.
//

import SwiftUI
import AppKit
import SwiftData


struct SubOperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TransactionDataManager
    @EnvironmentObject var formState: TransactionFormState

    @Binding var subOperation: EntitySousOperations?
    @Binding var isModeCreate: Bool

    @State private var comment           : String = ""
    @State private var selectedRubric    : EntityRubric?
    @State private var selectedCategorie : EntityCategory?
    @State private var amount            : String = ""
    
    @State private var isShowingDialog: Bool = false
    
    @State private var entityPreference : EntityPreference?
    @State private var entityRubric     : [EntityRubric] = []
    @State private var entityCategorie  : [EntityCategory] = []
    
    @State private var isExpanded = false // Indicateur l'état de sélection du signe


    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Split Transactions")
                .font(.headline)
                .padding(.bottom)

            TextField("Comment", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(String(localized: "Comment field"))
                .accessibilityHint(String(localized: "Enter a description for this sub-operation"))

            FormField(label: String(localized:"Rubric")) {
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

            FormField(label: String(localized:"Category")) {
                Picker("", selection: $selectedCategorie) {
                    ForEach(entityCategorie, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                }
                .accessibilityLabel(String(localized: "Category selection"))
                .accessibilityHint(String(localized: "Choose a category within the selected rubric"))
            }
            HStack {
                Text("Amount")
                ZStack {
                    Rectangle()
                        .fill(isExpanded ? Color.red : Color.green)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: isExpanded ? "minus" : "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .onTapGesture {
                    isExpanded.toggle()
                }

                TextField("Amount", text: $amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 20))
                    .foregroundColor(isExpanded ? .red : .green)

                    .accessibilityLabel(String(localized: "Amount field"))
                    .accessibilityHint(String(localized: "Enter the amount for this sub-operation"))
                    .accessibilityValue(amount.isEmpty ? String(localized: "No amount entered") :
                                            amount)
            }
            .padding(.bottom)


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
                        saveSubOperation()
                        dismiss() // Ferme la vue après sauvegarde
                }) {
                    Text("OK")
                        .frame(width: 100)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(5)
                }
                .disabled(comment == "") 
                .opacity(comment == "" ? 0.6 : 1)
            }
        }
        .padding()
        .onAppear {
            configureForm()
            if isModeCreate == false{
                comment = subOperation?.libelle ?? ""
                selectedCategorie = subOperation?.category
                selectedRubric    = subOperation?.category?.rubric
                amount = String(subOperation?.amount ?? 0.0)
                printSub()

            } else {
                
                let account = CurrentAccountManager.shared.getAccount()
                PreferenceManager.shared.configure(with: modelContext)
                self.entityPreference = PreferenceManager.shared.getAllDatas(for: account)
                
                comment = ""
                selectedCategorie = entityPreference!.category
                selectedRubric = entityPreference!.category?.rubric
                amount = String(0.0)
                
                printSub1()
            }
        }
    }
    
    func printSub() {
        print(subOperation?.libelle ?? "default")
        print(subOperation?.category?.rubric?.name ?? "nil")
        print(subOperation?.category?.name ?? "default")
        print(subOperation?.amount ?? 0.0)
    }
    
    func printSub1() {
        print(comment)
        print(selectedCategorie?.rubric?.name ?? "nil")
        print(selectedCategorie?.name ?? "default")
        print(amount)
    }

    func saveSubOperation()
    {
        if isModeCreate == true { // Création
            // Create entityTransaction
            ListTransactionsManager.shared.configure(with: modelContext)
            ListTransactionsManager.shared.createTransactions(formState: formState)
                       
            // Create entitySousOperation
            let amountDouble = (Double(amount) ?? 0.0) * (isExpanded ? -1 : 1)
            amount = String(amountDouble)
            printSub1()
            SubTransactionsManager.shared.createSubTransactions(comment: comment, category: selectedCategorie!, amount: amount, formState: formState)
            
            if formState.currentTransaction?.sousOperations == nil {
                formState.currentTransaction?.sousOperations = []
            }
            
            formState.currentTransaction?.addSubOperation(subOperation!)
            modelContext.insert(subOperation!)

        } else { // Edition
            if let subOperation = subOperation {
                updateSousOperation(subOperation)
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
        
        item.transaction = formState.currentTransaction

    }

    func configureManagers() async throws {
        RubricManager.shared.configure(with: modelContext)
        PreferenceManager.shared.configure(with: modelContext)
        PaymentModeManager.shared.configure(with: modelContext)
        SubTransactionsManager.shared.configure(with: modelContext)
        ListTransactionsManager.shared.configure(with: modelContext)
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



// MARK:  5. Composant pour la section des sous-opérations
struct SubOperationsSectionView: View {
    @Binding var subOperations: [EntitySousOperations]
    @Binding var currentSubOperation: EntitySousOperations?
    @Binding var isShowingDialog: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(String(localized: "Split Transactions"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            List {
                SubOperationListView(
                    subOperations: $subOperations,
                    currentSubOperation: $currentSubOperation,
                    isShowingDialog: $isShowingDialog
                )
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
        }
    }
}

struct SubOperationListView: View {
    @EnvironmentObject var formState: TransactionFormState

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
                .foregroundColor(.primary)
            Spacer()
            Text("\(subOperation.amount, format: .currency(code: "EUR"))")
                .foregroundColor(.red)
                .accessibilityLabel(String(localized: "Amount"))
                .accessibilityValue("\(subOperation.amount, format: .currency(code: "EUR"))")
            Spacer()
                .frame(width: 20)
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel(String(localized: "Edit sub-operation"))
            .accessibilityHint(String(localized: "Double tap to edit \(subOperation.libelle)"))
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibilityLabel(String(localized: "Delete sub-operation"))
            .accessibilityHint(String(localized: "Double tap to delete \(subOperation.libelle)"))
        }
    }
}

