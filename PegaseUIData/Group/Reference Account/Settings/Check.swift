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
    @Published var identity: EntityIdentity? {
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
    
    var account = CurrentAccountManager.shared.getAccount()!
    @State private var carnetCheques: [EntityCheckBook] = []
       
    @State private var selectedItem: EntityCheckBook.ID?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false // Nouveau état pour afficher le dialog d'édition
    @State private var itemToEdit: EntityCheckBook? // État pour stocker l'élément à éditer

    var body: some View {
        VStack(spacing: 10) {
            Text("Account: \(account.name)")
                .font(.headline)
            
            Table(carnetCheques, selection: $selectedItem) {
                
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
            .sheet(isPresented: $isAddDialogPresented) {
                AddDialogView { newCheckBook in
                    // Ajoute le nouvel élément à la liste
                    carnetCheques.append(newCheckBook)
                }
            }
            
            .sheet(item: $itemToEdit) { item in
                // Affiche la boîte de dialogue d'édition avec l'élément sélectionné
                EditDialogView(checkBook: Binding(
                    get: { item },
                    set: { updatedItem in
                        // Met à jour l'élément dans le tableau principal
                        if let index = carnetCheques.firstIndex(where: { $0.id == updatedItem.id }) {
                            carnetCheques[index] = updatedItem
                        }
                    }
                ))
            }
            .frame(height: 300)
            HStack {
                Button(action: { isAddDialogPresented = true }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { isEditDialogPresented = true }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action: removeSelectedItem) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
            Spacer()
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
struct AddDialogView: View {
    @Environment(\.dismiss) private var dismiss // Pour fermer la feuille
    @State private var name: String = ""
    @State private var nbCheques: Int = 0
    @State private var numPremier: Int = 0
    @State private var numSuivant: Int = 0
    @State private var prefix: String = ""

    var onAdd: (EntityCheckBook) -> Void // Callback pour transmettre l'élément ajouté

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Checkbook")
                .font(.headline)

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

            HStack {
                Button("Cancel") {
                    dismiss() // Ferme la boîte de dialogue
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

                Button("Add") {
                    // Crée un nouvel élément
                    let newCheckBook = EntityCheckBook(
                        name: name,
                        nbCheques: nbCheques,
                        numPremier: numPremier,
                        numSuivant: numSuivant,
                        prefix: prefix,
                        account: CurrentAccountManager.shared.getAccount()! // Associe le compte actuel
                    )
                    onAdd(newCheckBook) // Appelle le callback
                    dismiss() // Ferme la boîte de dialogue
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(name.isEmpty) // Désactive si le nom est vide
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct EditDialogView: View {
    @Binding var checkBook: EntityCheckBook
    @Environment(\.dismiss) private var dismiss // Pour fermer la feuille

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Checkbook")
                .font(.headline)
            
            TextField("Name", text: $checkBook.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Number of Checks", value: $checkBook.nbCheques, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("First Number", value: $checkBook.numPremier, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Next Number", value: $checkBook.numSuivant, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Prefix", text: $checkBook.prefix)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel") {
                    dismiss() // Ferme la feuille
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Button("Save") {
                    // Sauvegarde les modifications
                    // Vous pouvez ajouter une logique ici pour sauvegarder dans le contexte Core Data ou autre
                    dismiss() // Ferme la feuille
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
