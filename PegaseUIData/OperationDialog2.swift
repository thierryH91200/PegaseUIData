//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData

struct OperationDialog: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var transactionDataManager = TransactionDataManager()
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode : Bool

    var body: some View {
        VStack {
            OperationDialogView(selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode )
                .environmentObject(transactionDataManager)
                .environmentObject(currentAccountManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}

final class TransactionDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var transactions: [EntityTransactions]? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    private var modelContext: ModelContext?
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    func saveChanges() {
        guard let context = modelContext else {
            print("⚠️ modelContext is nil, changes not saved!")
            return
        }
        do {
            try context.save()
        } catch {
            print("❌ Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct SubOperationListView: View {
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


struct SubOperationDialog: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TransactionDataManager

    @Binding var subOperation: EntitySousOperations?
    @Binding var isModeCreate: Bool

    @State private var comment: String = ""
    @State private var rubrique: EntityRubric?
    @State private var category: EntityCategory?
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
                .accessibilityLabel(String(localized: "Comment field"))
                .accessibilityHint(String(localized: "Enter a description for this sub-operation"))

            FormField(label: "Rubric") {
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

            FormField(label: "Category") {
                Picker("", selection: $selectedCategorie) {
                    ForEach(entityCategorie, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                }
                .accessibilityLabel(String(localized: "Category selection"))
                .accessibilityHint(String(localized: "Choose a category within the selected rubric"))
            }

            TextField("Amount", text: $amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel(String(localized: "Amount field"))
                .accessibilityHint(String(localized: "Enter the amount for this sub-operation"))
                .accessibilityValue(amount.isEmpty ?
                    String(localized: "No amount entered") :
                    amount)

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
                        saveSubOperation(subOperation)
                        dismiss() // Ferme la vue après sauvegarde
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
        .onAppear {
            configureForm()
            if let subOperation = subOperation {
                amount = String(subOperation.amount)
                comment = subOperation.libelle
                category = subOperation.category
                rubrique = subOperation.category?.rubric
            }
        }
    }
    
    func saveSubOperation(_ subOperation: EntitySousOperations?)
    {
        if isModeCreate == true { // Création
            updateSousOperation(subOperation!)
            modelContext.insert(subOperation!)

        } else { // Modification
            if let existingItem = subOperation {
                updateSousOperation(existingItem)
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

struct SubOperationRow: View {
    let subOperation: EntitySousOperations
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(subOperation.libelle)
            Spacer()
            Text("\(subOperation.amount)")
                .foregroundColor(.red)
                .accessibilityLabel(String(localized: "Amount"))
                .accessibilityValue("\(subOperation.amount )")
            Spacer()
                .frame(width: 20)
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .accessibilityLabel(String(localized: "Edit sub-operation"))
            .accessibilityHint(String(localized: "Double tap to edit \(subOperation.libelle)"))
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .accessibilityLabel(String(localized: "Delete sub-operation"))
            .accessibilityHint(String(localized: "Double tap to delete \(subOperation.libelle)"))
        }
    }
}
