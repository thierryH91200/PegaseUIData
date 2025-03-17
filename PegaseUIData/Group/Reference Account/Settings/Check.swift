//
//  Check.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData


// Gestionnaire de données pour les carnets de chèques
final class CheckDataManager: ObservableObject {
    @Published var checkBooks: [EntityCheckBook]?
    {
            didSet {
                // Sauvegarde automatique dès qu'une modification est détectée
                saveChanges()
            }
        }
    
    private var modelContext: ModelContext?
    
    // Configure le contexte de modèle pour la gestion des données
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // Sauvegarde les modifications dans SwiftData
    func saveChanges() {
        guard let modelContext = modelContext else {
            print("Le contexte de modèle n'est pas initialisé.")
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
    // Ajoute un nouveau carnet de chèques
    func addCheckBook(name: String, nbCheques: Int, numPremier: Int, numSuivant: Int, prefix: String, account: EntityAccount?) {
        guard let modelContext = modelContext else {
            print("Le contexte de modèle n'est pas initialisé.")
            return
        }
        
        let newCheckBook = EntityCheckBook()
        newCheckBook.name = name
        newCheckBook.nbCheques = nbCheques
        newCheckBook.numPremier = numPremier
        newCheckBook.numSuivant = numSuivant
        newCheckBook.prefix = prefix
        newCheckBook.account = account
        
        modelContext.insert(newCheckBook)
        
        // Ajoute à la liste
        if checkBooks == nil {
            checkBooks = [newCheckBook]
        } else {
            checkBooks?.append(newCheckBook)
        }
        saveChanges()
    }

    // Supprime un carnet de chèques
    func deleteCheckBook(_ checkBook: EntityCheckBook) {
        guard let modelContext = modelContext else {
            print("Le contexte de modèle n'est pas initialisé.")
            return
        }
        
        modelContext.delete(checkBook)
        
        // Met à jour la liste
        checkBooks?.removeAll { $0.id == checkBook.id }
        
        saveChanges()
    }
}

// Vue principale pour l'affichage des carnets de chèques
struct CheckView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: CheckDataManager
    
    @State private var selectedItem: EntityCheckBook.ID? = nil
    @State private var selectedCheck: EntityCheckBook?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var isModeCreate = false
        
    var body: some View {
        VStack(spacing: 10) {
            // Affiche le compte actuel
            if let account = currentAccountManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            
            // Table des carnets de chèques
            CheckBookTable(checkBooks: dataManager.checkBooks ?? [], selection: $selectedItem)
                .frame(height: 300)
                // Mise à jour de l'élément sélectionné
                .onChange(of: selectedItem) { _, newValue in
                    selectedCheck = dataManager.checkBooks?.first(where: { $0.id == newValue })
                }
                .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                    // Mise à jour de la liste en cas de changement de compte
                        dataManager.checkBooks = []
                        selectedCheck = nil
                        selectedItem = nil
                        refreshData()
                }
                // Charge les données au démarrage de la vue
                .onAppear {
                    setupDataManager()
//                    currentAccount = currentAccountManager.currentAccount
                }
            
            // Boutons d'action
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    isModeCreate = true
                }) {
                    Label("Add", systemImage: "plus")
                        .buttonStyle(.borderedProminent)
                }
                
                Button(action: {
                    isEditDialogPresented = true
                    isModeCreate = false
                }) {
                    Label("Edit", systemImage: "pencil")
                        .buttonStyle(.bordered)
                }
                .disabled(selectedItem == nil)
                
                Button(action: delete) {
                    Label("Delete", systemImage: "trash")
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
                .disabled(selectedItem == nil)
            }
            
            // Feuilles modales pour l'ajout/modification
            .sheet(isPresented: $isEditDialogPresented) {
                CheckBookFormView(isPresented: $isEditDialogPresented, isModeCreate: $isModeCreate, checkBook: selectedCheck)
            }
            .sheet(isPresented: $isAddDialogPresented) {
                CheckBookFormView(isPresented: $isAddDialogPresented, isModeCreate: $isModeCreate, checkBook: nil)
            }
            .padding()
            Spacer()
        }
    }
    
    // Configure le gestionnaire de données
    private func setupDataManager() {
        ChequeBookManager.shared.configure(with: modelContext)
        dataManager.configure(with: modelContext)
        dataManager.checkBooks = ChequeBookManager.shared.getAllDatas()
    }
    
    // Supprime un carnet de chèques sélectionné
    private func delete() {
        if let checkBookToDelete = selectedCheck {
            dataManager.deleteCheckBook(checkBookToDelete)
            selectedCheck = nil
            selectedItem = nil
        }
    }
    
    // Rafraîchit la liste des carnets de chèques
    private func refreshData() {
        dataManager.checkBooks = ChequeBookManager.shared.getAllDatas()
    }
}

struct CheckBookTable: View {
    
    var checkBooks: [EntityCheckBook]
    @Binding var selection: EntityCheckBook.ID?
    
    var body: some View {
        
        Table(checkBooks, selection: $selection) {
            
            TableColumn( "Name", value: \EntityCheckBook.name)
            
            TableColumn( "Number of Checks") { (item: EntityCheckBook) in
                Text(String(item.nbCheques))
            }
            
            TableColumn( "First Number") { (item: EntityCheckBook) in
                Text(String(item.numPremier))
            }
            
            TableColumn( "Next Number") { (item: EntityCheckBook) in
                Text(String(item.numSuivant))
            }
            
            TableColumn( "Prefix") { (item: EntityCheckBook) in
                Text(item.prefix)
            }
            
            TableColumn( "Name") { item in
                Text(item.account!.identity?.name ?? "")
            }
            
            TableColumn( "Surname") { (item: EntityCheckBook) in
                Text(item.account!.identity?.surName ?? "")
            }
            
            TableColumn( "Number") { item in
                Text(item.account!.initAccount?.codeAccount ?? "")
            }
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct CheckBookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var checkViewManager: CheckDataManager
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    
    let checkBook: EntityCheckBook?
    @State private var name: String = ""
    @State private var nbCheques: Int = 0
    @State private var numPremier: Int = 0
    @State private var numSuivant: Int = 0
    @State private var prefix: String = ""
    
    var body: some View {
        VStack(spacing: 0) { // Spacing à 0 pour que les bandeaux soient collés au contenu
            // Bandeau du haut
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                Text(isModeCreate ? "Add CheckBook" : "Edit CheckBook")
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                HStack {
                    Text("Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Number of Checks")
                        .frame(width: 100, alignment: .leading)
                    TextField("", value: $nbCheques, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("First Number")
                        .frame(width: 100, alignment: .leading)
                    TextField("", value: $numPremier, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Next Number")
                        .frame(width: 100, alignment: .leading)
                    TextField("", value: $numSuivant, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("Prefix")
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $prefix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Spacer()
            }
            .padding()
            .navigationTitle(checkBook == nil ? "New checkBook" : "Edit CheckBook")
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
                    .disabled(prefix.isEmpty || name.isEmpty || numPremier <= 0 || numSuivant <= 0 || nbCheques <= 0)
                    .opacity(prefix.isEmpty || name.isEmpty || numPremier <= 0 || numSuivant <= 0 || nbCheques <= 0 ? 0.6 : 1)
                }
            }
            .frame(width: 400)
            
            // Bandeau du bas
            Rectangle()
                .fill(isModeCreate ? Color.blue : Color.green)
                .frame(height: 10)
        }
        .onAppear {
            if let checkBook = checkBook {
                name = checkBook.name
                nbCheques = checkBook.nbCheques
                numPremier = checkBook.numPremier
                numSuivant = checkBook.numSuivant
                prefix = checkBook.prefix
            }
        }
    }
    
    private func save() {
        if isModeCreate { // Création
            checkViewManager.addCheckBook(
                name: name,
                nbCheques: nbCheques,
                numPremier: numPremier,
                numSuivant: numSuivant,
                prefix: prefix,
                account: CurrentAccountManager.shared.getAccount()
            )
        } else { // Modification
            if let existingItem = checkBook {
                existingItem.name = name
                existingItem.nbCheques = nbCheques
                existingItem.numPremier = numPremier
                existingItem.numSuivant = numSuivant
                existingItem.prefix = prefix
                try? modelContext.save()
            }
        }
        
        isPresented = false
        dismiss()
    }
    
    private func updateCheckBook(_ item: EntityCheckBook) {
        item.name = name
        item.nbCheques = nbCheques
        item.numPremier = numPremier
        item.numSuivant = numSuivant
        item.prefix = prefix
    }
}
