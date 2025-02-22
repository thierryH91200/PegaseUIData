//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 22/02/2025.
//

import SwiftUI
import AppKit
import SwiftData



// MARK: - SousOperationFormView
struct SousOperationFormView: View {
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var mode: Bool
    
     @State var comment : String = ""
    @State var amount : String = ""
    
    @State private var entityPreference : EntityPreference?
    @State private var entityRubric : [EntityRubric] = []
    @State private var entityCategorie : [EntityCategory] = []
    
    @State private var selectedRubric    : EntityRubric?
    @State private var selectedCategorie : EntityCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Ligne 1 : Comment
            
            FormField(label: "Comment") {
                TextField("", text: $comment)
            }
            
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
    
    func save() {
        
    }
}
