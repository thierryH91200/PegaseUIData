//
//  Check.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData


// Vue principale pour l'affichage des carnets de chèques
struct CheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: ChequeBookManager
    
    @State private var checkBooks: [EntityCheckBook] = []

    @State private var selectedItem: EntityCheckBook.ID?
    @State private var lastDeletedID: UUID?

    var selectedCheckBook: EntityCheckBook? {
        guard let id = selectedItem else { return nil }
        return checkBooks.first(where: { $0.id == id })
    }

    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var isModeCreate = false
    
    var canUndo : Bool? {
        undoManager?.canUndo ?? false
    }
    var canRedo : Bool? {
        undoManager?.canRedo ?? false
    }

    var body: some View {
        VStack(spacing: 10) {
            // Affiche le compte actuel
            if let account = currentAccountManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            
            // Table des carnets de chèques
            CheckBookTable(checkBooks: dataManager.checkBooks, selection: $selectedItem)
                .frame(height: 300)
            
                .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in
                    printTag("Undo effectué, on recharge les données")
                    refreshData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in
                    printTag("Redo effectué, on recharge les données")
                    refreshData()
                }

            
                // Mise à jour de l'élément sélectionné
                .onChange(of: selectedItem) { _, newValue in
                    if let selected = newValue {
                        selectedItem = selected
                    } else {
                        selectedItem = nil
                    }
                }
                .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                    // Mise à jour de la liste en cas de changement de compte
                    dataManager.checkBooks.removeAll()
                    selectedItem = nil
                    refreshData()
                }
            
                // Charge les données au démarrage de la vue
                .onAppear {
//                    DataContext.shared.context = modelContext
                    setupDataManager()
                }

            // Boutons d'action
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    isModeCreate = true
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isEditDialogPresented = true
                    isModeCreate = false
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil)
                
                Button( action: {
                    delete()
                    setupDataManager()
                }) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(selectedItem == nil ? Color.gray : Color.red) // Fond gris si désactivé
                        .opacity(selectedItem == nil ? 0.6 : 1) // Opacité réduite si désactivé
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil)
#if !DEBUG
                Button(action: {
                    if let manager = undoManager, manager.canUndo {
                        selectedItem = nil
                        lastDeletedID = nil
                        
                        manager.undo()
                        
                        DispatchQueue.main.async {
                            refreshData()
                        }
                    }
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background(canUndo == false ? Color.gray : Color.green)
                        .opacity(canUndo == false  ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
#endif // DEBUG
#if DEBUG

                
                Button(action: {
                    if let manager = undoManager, manager.canRedo {
                        selectedItem = nil
                        lastDeletedID = nil

                        manager.redo()

                        DispatchQueue.main.async {
                            refreshData()
                        }
                    }
                }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background( canRedo == false ? Color.gray : Color.orange)
                        .opacity( canRedo  == false ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
#endif

            }
            
            // Feuilles modales pour l'ajout/modification
            .sheet(isPresented: $isEditDialogPresented, onDismiss: {setupDataManager()})
            {
                CheckBookFormView(
                    isPresented: $isEditDialogPresented,
                    isModeCreate: $isModeCreate,
                    checkBook: selectedCheckBook)
            }
            .sheet(isPresented: $isAddDialogPresented , onDismiss: {setupDataManager()})
            {
                CheckBookFormView(
                    isPresented: $isAddDialogPresented,
                    isModeCreate: $isModeCreate,
                    checkBook: nil)
            }
            .padding()
            Spacer()
        }
    }
    
    // Configure le gestionnaire de données
    private func setupDataManager() {
        DataContext.shared.context = modelContext
        DataContext.shared.undoManager = undoManager

        if currentAccountManager.currentAccount != nil {
            if let allData = ChequeBookManager.shared.getAllData() {
                dataManager.checkBooks = allData
                checkBooks = allData
            } else {
                print("❗️Erreur : getAllData() a renvoyé nil")
            }
        }
    }
    
    // Supprime un carnet de chèques sélectionné
    private func delete() {
        
        if let id = selectedItem,
           let item = checkBooks.first(where: { $0.id == id }) {
            
            lastDeletedID = item.id
            
            ChequeBookManager.shared.delete(entity: item, undoManager: undoManager)

            DispatchQueue.main.async {
                selectedItem = nil
                lastDeletedID = nil
                refreshData()
            }
        }
    }
    
    // Rafraîchit la liste des carnets de chèques
    private func refreshData() {
        dataManager.checkBooks = ChequeBookManager.shared.getAllData()!
        checkBooks = dataManager.checkBooks
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
        .tableStyle(.bordered)
    }
}

// Vue pour la boîte de dialogue d'ajout
struct CheckBookFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: ChequeBookManager
    
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
            ChequeBookManager.shared.create(
                name: name,
                nbCheques: nbCheques,
                numPremier: numPremier,
                numSuivant: numSuivant,
                prefix: prefix
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
