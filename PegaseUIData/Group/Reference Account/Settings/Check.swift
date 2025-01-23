//
//  Check.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI



struct CheckView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    var account = CurrrentAccountManager.shared.getAccount()!
    @State private var carnetCheques: [EntityCheckBook] = []
       
    @State private var selectedItem: EntityCheckBook.ID?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false // Nouveau état pour afficher le dialog d'édition
       
    var body: some View {
        VStack(spacing: 10) {
            Text("Account: \(account.name)")
                .font(.headline)
            
            Table(carnetCheques, selection: $selectedItem) {
                
                TableColumn( "Name", value: \EntityCheckBook.name)
                
                TableColumn( "Number of Checks") { (item: EntityCheckBook) in
                    Text(String(item.nbCheques))
                }

                TableColumn( "First number") { (item: EntityCheckBook) in
                    Text(String(item.numPremier))
                }
                
                TableColumn( "Next number") { (item: EntityCheckBook) in
                    Text(String(item.numSuivant))
                }
                
                TableColumn( "Prefix") { (item: EntityCheckBook) in
                    Text(item.prefix)
                }

                TableColumn( "Surname") { (item: EntityCheckBook) in
                    Text(item.account.identity?.surName ?? "")
                }
                
                TableColumn( "Name") { item in
                    Text(item.account.identity?.name ?? "")
                }
                
                TableColumn( "Number") { item in
                    Text(item.account.initAccount?.codeAccount ?? "")
                }
            }
            .onAppear {
                Task {
                    ChequeBookManager.shared.configure(with: modelContext)
                    carnetCheques = await ChequeBookManager.shared.getAllDatas(for: account)
                    
                    if let firstItem = carnetCheques.first {
                        print("First item ID: \(firstItem.id)") // Vérifie que l'ID existe
                    } else {
                        print("No items in ChequeBook")
                    }
                }
            }
            
            .frame(height: 300)
            HStack {
                Button(action: { isAddDialogPresented = true }) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                
                Button(action: { isEditDialogPresented = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action: removeSelectedItem) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
            Spacer()
        }
    }
    private func addItem(name: String) {
        print("account : ", account.name)
        ChequeBookManager.shared.configure(with: modelContext)
        let entity = ChequeBookManager.shared.create(account: account, name: name)

        modelContext.insert(entity!) // Ajoutez l'entité au contexte
        
        do {
            // Sauvegardez le contexte pour persister les modifications
            try modelContext.save()
            print("Cheque book added successfully.")
        } catch {
            print("Erreur lors de l'ajout de l'entité : \(error)")
        }
    }
    
    private func editItem(name: String, nbCheques: String, checkBook: EntityCheckBook) {
        print("Editing item: \(checkBook.name)")
        
        // Mettre à jour les propriétés de l'élément dans SwiftData
        ChequeBookManager.shared.configure(with: modelContext)
        ChequeBookManager.shared.update(entity: checkBook, name: name)
        
        // Recharger la liste des éléments
        if let index = carnetCheques.firstIndex(where: { $0.id == checkBook.id }) {
            carnetCheques[index].name = name
            carnetCheques[index].nbCheques = Int(nbCheques)!
        }
    }
    
    private func removeSelectedItem() {
        
        if let selectedID = selectedItem, let mode = carnetCheques.first(where: { $0.id == selectedID }) {
            print("Removing item with ID \(selectedID)")

            // Supprimez l'entité du contexte de données
            modelContext.delete(mode)

            // Sauvegardez les changements dans le contexte
            do {
                try modelContext.save()
                selectedItem = nil // Réinitialise la sélection
            } catch {
                print("Erreur lors de la suppression de l'entité : \(error)")
            }
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct AddItemDialogScheduler: View {
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var numPremier: String = ""
    @State private var numSuivant: String = ""
    @State private var prefix: String = ""

    var onAdd: (String, String, String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Check Book")
                .font(.headline)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            TextField("nbCheques", text: $name)
                .textFieldStyle(.roundedBorder)
            
            TextField("First number", text: $numPremier)
                .textFieldStyle(.roundedBorder)
            
            TextField("Next number", text: $numSuivant)
                .textFieldStyle(.roundedBorder)

            TextField("Prefix", text: $prefix)
                .textFieldStyle(.roundedBorder)


            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("OK") {
                    if !name.isEmpty {
                        onAdd(name, numPremier, numSuivant, prefix  )
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty) // Désactive le bouton si le nom est vide
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct EditItemDialogScheduler: View {
    @Binding var isPresented: Bool
    @State var name: String
    @State var selectedColor: Color
    
    var onEdit: (String, Color) -> Void
    
    init(isPresented: Binding<Bool>, paymentMode: EntityPaymentMode, onEdit: @escaping (String, Color) -> Void) {
        self._isPresented = isPresented
        self._name = State(initialValue: paymentMode.name)
        self._selectedColor = State(initialValue: Color(paymentMode.color))
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Payment Mode")
                .font(.headline)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            ColorPicker("Choose the color", selection: $selectedColor)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    if !name.isEmpty {
                        onEdit(name, selectedColor)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
