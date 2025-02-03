//
//  Check.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData


final class CheckViewManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var checkBooks: [EntityCheckBook]? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    func saveChanges(using context: ModelContext? = nil) {
        guard let context = context else { return }
        
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct CheckView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var checkViewManager : CheckViewManager
        
    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityCheckBook.ID? = nil
    @State private var selectedCheck: EntityCheckBook?
    
    @Query private var carnetCheques: [EntityCheckBook] = []
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var modeCreate = false
    
    var body: some View {
        VStack(spacing: 10) {
            if let account = checkViewManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            CheckBookTable(checkBooks: checkViewManager.checkBooks ?? [], selection: $selectedItem )
                .frame(height: 300)
            
                .onChange(of: selectedItem) { oldValue, newValue in
                    selectedCheck = nil // Désactive l’édition automatique
                    selectedItem = nil
                    
                    if let selectedId = newValue,
                       let selected = carnetCheques.first(where: { $0.id == selectedId }) {
                        selectedCheck = selected
                        selectedItem = selected.id
                    } else {
                        print("Aucun élément sélectionné dans CheckView/onChange")
                    }
                }
            
                .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                    
                    if let account = newAccount {
                        checkViewManager.checkBooks = nil
                        checkViewManager.currentAccount = account
                        selectedCheck = nil
                        selectedItem = nil
                        loadOrCreate(for: account)
                    }
                }
            
                .onAppear {
                    Task {
                        
                        if let account = currentAccountManager.currentAccount {
                            checkViewManager.currentAccount = account
                        } else {
                            print("Aucun compte disponible.")
                        }
                        
                        // Créer un nouvel enregistrement si la base de données est vide
                        if checkViewManager.checkBooks == nil {
                            if let account = CurrentAccountManager.shared.getAccount() {
                                checkViewManager.currentAccount = account
                            } else {
                                print("Aucun compte disponible.")
                            }
                            ChequeBookManager.shared.configure(with: modelContext)
                            let checkBooks = ChequeBookManager.shared.getAllDatas()
                            checkViewManager.checkBooks = checkBooks
                            
                            if checkBooks == nil {
                                
                                let entity = EntityCheckBook()
                                checkViewManager.checkBooks!.append( entity   )
                                modelContext.insert(entity)
                            }
                        }
                    }
                }
            
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    modeCreate = true
                    
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isEditDialogPresented = true
                    modeCreate = false
                    
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action:
                        delete
                ) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            
            .sheet(isPresented: $isEditDialogPresented) {
                CheckBookFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, checkBook: selectedCheck)
            }
            
            .sheet(isPresented: $isAddDialogPresented) {
                CheckBookFormView(isPresented: $isAddDialogPresented, mode: $modeCreate, checkBook: nil)
            }
            
            .padding()
            Spacer()
        }
    }
    
    private func delete() {
        guard let selectedCheck else { return }
        modelContext.delete(selectedCheck)
        
        if selectedItem == selectedCheck.id {
            selectedItem = nil
        }
        
        try? modelContext.save()
    }
    
    private func loadOrCreate(for account: EntityAccount?) {
        guard let account else { return }
        
        ChequeBookManager.shared.configure(with: modelContext)
        if let existing = ChequeBookManager.shared.getAllDatas() {
            checkViewManager.checkBooks = existing
        } else {
            let entity = EntityCheckBook()
            entity.account = account
            modelContext.insert(entity)
            checkViewManager.checkBooks!.append( entity)
        }
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
    @EnvironmentObject var checkViewManager: CheckViewManager
    
    @Binding var isPresented: Bool
    @Binding var mode: Bool
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
                .fill(mode ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                Text(mode ? "Add CheckBook" : "Edit CheckBook")
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
                }
            }
            .frame(width: 400)
            
            // Bandeau du bas
            Rectangle()
                .fill(mode ? Color.blue : Color.green)
                .frame(height: 10)
        }
        .onAppear {
            if let checkBook = checkBook {
                print("Chargement de l'élément à éditer : \(checkBook.name)")
                name = checkBook.name
                nbCheques = checkBook.nbCheques
                numPremier = checkBook.numPremier
                numSuivant = checkBook.numSuivant
                prefix = checkBook.prefix
            } else {
                print("appear checkBook is empty")
            }
        }
    }
    
    private func save() {
        if mode { // Création
            let newItem = EntityCheckBook()
            updateCheckBook(newItem)
            if let account = CurrentAccountManager.shared.getAccount() {
                newItem.account = account
            }
            modelContext.insert(newItem)
            checkViewManager.checkBooks?.append(newItem)
        } else { // Modification
            if let existingItem = checkBook {
                updateCheckBook(existingItem)
            }
        }
        
        try? modelContext.save()
    }
    
    private func updateCheckBook(_ item: EntityCheckBook) {
        item.name = name
        item.nbCheques = nbCheques
        item.numPremier = numPremier
        item.numSuivant = numSuivant
        item.prefix = prefix
    }
}
