//
//  Rubric.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//


import SwiftUI
import SwiftData

final class RubricDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var rubrics: [EntityRubric] = []
    
    private var modelContext: ModelContext?
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    func saveChanges() {
        do {
            try modelContext?.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct RubricView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var dataManager : RubricDataManager
    
    @State private var rubriques: [EntityRubric] = []
    
    @State private var expandedRubriques: [String: Bool] = [:]
    @State private var selectedCategory: EntityCategory?
    @State private var selectedRubric: EntityRubric?
    
    @State private var isAddDialogRubricPresented = false
    @State private var isEditDialogRubricPresented = false
    @State private var isAddDialogCategoryPresented = false
    @State private var isEditDialogCategoryPresented = false
    @State private var modeCreate = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if let account = dataManager.currentAccount {
                    Text("Account: \(account.name)")
                        .font(.headline)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        rubricList()
                            .padding(.vertical, 0)
                    }
                    .padding(10)
                }
                
                .onChange(of: selectedCategory) { oldValue, newValue in
                }
                
                .onChange(of: currentAccountManager.currentAccount ) { old, newAccount in
                    if let account = newAccount {
                        dataManager.rubrics.removeAll()
                        dataManager.currentAccount = account
                        selectedCategory = nil
                        selectedRubric = nil
                        
                        rubriques = RubricManager.shared.getAllDatas()
                        dataManager.rubrics = rubriques
                    }
                }
                
                .onAppear {
                    dataManager.configure(with: modelContext)
                    RubricManager.shared.configure(with: modelContext)
                    
                    rubriques = RubricManager.shared.getAllDatas()
                    dataManager.rubrics = rubriques
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)
                
                Spacer(minLength: 0)
                
                HStack {
                    Button(action: {
                        modeCreate = true
                        if selectedRubric != nil {
                            isAddDialogRubricPresented = true
                        }
                        else {
                            isAddDialogCategoryPresented = true
                        }
                    }) {
                        let label = selectedRubric != nil ? "Add Rubric" : "Add Category"
                        Label(label, systemImage: "plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fixedSize() // Ajuste automatiquement la taille au contenu
                    }
                    
                    Button(action: {
                        modeCreate = false
                        if selectedRubric != nil {
                            isEditDialogRubricPresented = true
                        }
                        else {
                            isEditDialogCategoryPresented = true
                        }

                    }) {
                        let label = selectedRubric != nil ? "Edit Rubric" : "Edit Category"
                        Label(label, systemImage: "pencil")
                            .padding()
                            .background((selectedRubric == nil && selectedCategory == nil) ? Color.gray : Color.green) // Fond gris si désactivé
                            .opacity((selectedRubric == nil && selectedCategory == nil) ? 0.6 : 1) // Opacité réduite si désactivé
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fixedSize() // Ajuste automatiquement la taille au contenu

                    }
                    .disabled(selectedRubric == nil && selectedCategory == nil) // Désactive si aucune ligne n'est sélectionnée
                    
                    Button(action: {
                        removeCategorySelectedItem()
                        refreshData()
                    })
                    {
                        let label = selectedRubric != nil ? "Delete Rubric" : "Delete Category"
                        Label(label, systemImage: "trash")
                            .padding()
                            .background((selectedRubric == nil && selectedCategory == nil) ? Color.gray : Color.red) // Fond gris si désactivé
                            .opacity((selectedRubric == nil && selectedCategory == nil) ? 0.6 : 1) // Opacité réduite si désactivé
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fixedSize() // Ajuste automatiquement la taille au contenu
                    }
                    .disabled(selectedRubric == nil && selectedCategory == nil) // Désactive si aucune ligne n'est sélectionnée
                }
                .padding()
                Spacer()
            }
            .frame(width: 400, height: 500)
            .padding()
            .position(x: geometry.size.width / 2, y: 0)
            .offset(y: 350) // Ajustez cette valeur selon vos besoins
            
            .sheet(isPresented: $isAddDialogRubricPresented) {
                RubricFormView(isPresented: $isAddDialogRubricPresented, isMode: $modeCreate, rubric: nil)
            }
            .sheet(isPresented: $isEditDialogRubricPresented) {
                RubricFormView(isPresented: $isEditDialogRubricPresented, isMode: $modeCreate, rubric: selectedRubric)
            }
            .sheet(isPresented: $isAddDialogCategoryPresented) {
                CategoryFormView(isPresented: $isAddDialogCategoryPresented, isModeCreate: $modeCreate, rubric: nil, category: nil)
            }
            .sheet(isPresented: $isEditDialogCategoryPresented) {
                let rubric = selectedCategory!.rubric
                CategoryFormView(isPresented: $isEditDialogCategoryPresented, isModeCreate: $modeCreate, rubric: rubric, category: selectedCategory)
            }
        }
    }
    private func removeCategorySelectedItem() {
        if selectedRubric != nil {
            modelContext.delete(selectedRubric!)
        } else {
            modelContext.delete(selectedCategory!)

        }

    }
    
    func refreshData() {
        rubriques = RubricManager.shared.getAllDatas()
        dataManager.rubrics = rubriques
    }
    
    private func removeRubric(_ rubric: EntityRubric) {
        modelContext.delete(rubric)
        refreshData()
    }
    
    private func removeCategory(_ category: EntityCategory) {
        modelContext.delete(category)
        refreshData()
    }
    
    // Fonction séparée pour générer la liste des rubriques
    @ViewBuilder
    private func rubricList() -> some View {
        ForEach(rubriques, id: \.name) { rubrique in
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedRubriques[rubrique.name] ?? true },
                    set: { expandedRubriques[rubrique.name] = $0 }
                )
            ) {
                VStack(spacing: 0) {
                    ForEach(rubrique.categorie, id: \.name) { category in
                        categoryRow(category)
                    }
                }
            } label: {
                HStack {
                    Text(rubrique.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(rubrique.color))
                        .frame(height: 20)
                    Spacer()
                    Rectangle()
                        .fill(Color(rubrique.color))
                        .frame(width: 40, height: 10)
                }
                .padding(.vertical, 2)
                .background(selectedRubric?.name == rubrique.name ? Color.blue.opacity(0.3) : Color.clear) // ✅ Sélection uniquement sur la rubrique
                .onTapGesture {
                    selectedRubric = rubrique
                    selectedCategory = nil
                }
            }
            .contextMenu {
                Button(action: {
                    isAddDialogRubricPresented = true
                    modeCreate = true
                }) {
                    Label("Add the rubric", systemImage: "plus")
                }
                
                Button(action: {
                    isEditDialogRubricPresented = true
                    modeCreate = false
                }) {
                    Label("Edit the rubric", systemImage: "pencil")
                }
                
                Button(action: {
                    removeRubric(rubrique)
                }) {
                    Label("Delete the rubric", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // Fonction pour afficher chaque catégorie avec une ligne HStack
    @ViewBuilder
    private func categoryRow(_ category: EntityCategory) -> some View {
        HStack {
            Text(category.name)
                .font(.system(size: 12))
                .frame(minWidth: 150, alignment: .leading)
            Text("🎯 \(category.objectif.description)")
                .font(.system(size: 12))
        }
        .padding(.leading, 5)
        .frame(height: 18)
        .background(selectedCategory?.name == category.name ? Color.blue.opacity(0.3) : Color.clear)
        .onTapGesture {
            selectedRubric = nil
            selectedCategory = category
        }
        .contextMenu {  // Ajout du menu contextuel
            Button(action: {
                isAddDialogCategoryPresented = true
                modeCreate = true
            }) {
                Label("Add the category", systemImage: "plus")
            }
            
            Button(action: {
                isEditDialogCategoryPresented = true
                modeCreate = false
            }) {
                Label("Edit the category", systemImage: "pencil")
            }
            
            Button(action: {
                removeCategory(category)
            }) {
                Label("Remove the category", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct RubricFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rubricViewManager: RubricDataManager
    
    @Binding var isPresented: Bool
    @Binding var isMode: Bool
    let rubric: EntityRubric?
    @State private var name: String = ""
    @State private var selectedColor: Color = .gray
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isMode ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                
                Text(isMode ? "Add the rubric" : "Edit Rubric")
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                ColorPicker("Choose the color", selection: $selectedColor)
                    .frame(height: 50)
            }
            .padding()
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
            // Bandeau du bas
            .frame(width: 300)
            
            Rectangle()
                .fill(isMode ? Color.blue : Color.green)
                .frame(height: 10)
            
                .onAppear {
                    if let rubric = rubric {
                        name = rubric.name
                        selectedColor = Color(rubric.color)
                    }
                }
        }
    }
    
    private func save() {
        let newItem: EntityRubric
        let account = rubricViewManager.currentAccount
        
        if let existing = rubric {
            newItem = existing
        } else {
            let color = NSColor.fromSwiftUIColor(selectedColor)
            newItem = EntityRubric(name: name, color: color, account: account!)
            modelContext.insert(newItem)
            //            rubricViewManager.rubrics.append(newItem) // ✅ Ajouter à la liste
        }
        
        newItem.name = name
        newItem.color = NSColor.fromSwiftUIColor(selectedColor)
        newItem.account = CurrentAccountManager.shared.getAccount()!
        
        try? modelContext.save()
    }
}

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rubricViewManager: RubricDataManager
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    let rubric: EntityRubric?
    let category: EntityCategory?
    @State private var name: String = ""
    @State private var objectif: String = ""
    @State private var selectedColor: Color = .gray
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                
                Text(isModeCreate ? "Add the category" : "Edit the category")
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Objectif", text: $objectif)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
            
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
            // Bandeau du bas
                .frame(width: 200)
            
                .onAppear {
                    if let category = category {
                        name = category.name
                        objectif = String(category.objectif)
                    }
                }
        }
    }
    
    private func save() {
        let newItem: EntityCategory
        
        if let existing = category {
            newItem = existing
        } else {
            newItem = EntityCategory(name: name, objectif: Double(objectif) ?? 0.0, rubric: rubric!)
            modelContext.insert(newItem)
//            rubricViewManager.rubrics.append(newItem)
        }
        
        newItem.name = name
        newItem.objectif = Double(objectif) ?? 0.0
        
        try? modelContext.save()
    }
}

