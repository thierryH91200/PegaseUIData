//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI

struct ModePaymentView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var accountManager = CurrrentAccountManager.shared

    var account = CurrrentAccountManager.shared.getAccount()!

    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID? = nil
    
    @State private var modePayments: [EntityPaymentMode] = []
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false // Nouveau état pour afficher le dialog d'édition

    var body: some View {
        VStack(spacing: 10) {
            Table(modePayments, selection: $selectedItem) {
                TableColumn("Name", value: \EntityPaymentMode.name)
                TableColumn("Color") { item in
                    Rectangle()
                        .fill(Color(item.color))
                        .frame(width: 40, height: 20)
                }
                TableColumn("Account", value: \EntityPaymentMode.account!.name)
                TableColumn("Surname") { paymentMode in
                    Text(paymentMode.account!.identity?.surName ?? "Unknown") }
                TableColumn("First name")  { paymentMode in
                    Text(paymentMode.account!.identity?.name ?? "Unknown") }
                TableColumn("Number") { paymentMode in
                    Text(paymentMode.account!.initAccount?.codeAccount ?? "Unknown") }
            }
            .frame(height: 300)
            HStack {
                Button(action: {
                    addItem(name: "Default Name", color: .blue)
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isEditDialogPresented = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée

                Button(action: removeSelectedItem)
                {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Utilise tout l'espace parent et aligne en haut
        .padding()
        .onChange(of: CurrrentAccountManager.shared.currentAccount!) { old, newAccount in
            print(newAccount.name)
            // Rafraîchir les données` quand le compte change
            loadDatas(for: newAccount)
        }
        .onAppear {
            // Charger les paiements lors du premier affichage
                loadDatas(for: account)
        }
        .sheet(isPresented: $isEditDialogPresented) {
            if let selectedID = selectedItem,
               let selectedMode = modePayments.first(where: { $0.id == selectedID }) {
                EditItemDialog(
                    isPresented: $isEditDialogPresented,
                    paymentMode: selectedMode
                ) { updatedName, updatedColor in
                    editItem(name: updatedName, color: updatedColor, paymentMode: selectedMode)
                }
            }
        }
    }
    
    func loadDatas(for account: EntityAccount) {
        
        PaymentModeManager.shared.configure(with: modelContext)

        // Chargement asynchrone des données
        modePayments = PaymentModeManager.shared.getAllDatas(for: account)

        if let firstItem = modePayments.first {
            print("First item ID: \(firstItem.id)") // Vérifie que l'ID existe
        } else {
            print("No items in modePayments")
        }
    }

    private func addItem(name: String, color: Color) {
        print("account : ", account.name)
        PaymentModeManager.shared.configure(with: modelContext)
        let viewModel = PaymentModeViewModel(account: account)
        let account = viewModel.account
        
        do {
            // Essayez de créer l'entité
            if let entity = try PaymentModeManager.shared.create(account: account, name: name, color: NSColor.fromSwiftUIColor(color)){
                
                // Ajoutez l'entité au contexte
                modelContext.insert(entity)
            } else {
                print("Erreur : L'entité n'a pas pu être créée.")
            }

            // Sauvegardez le contexte pour persister les modifications
            try modelContext.save()
            print("Payment mode added successfully.")
        } catch {
            // Gérer l'erreur en cas d'échec
            print("Erreur lors de l'ajout de l'entité : \(error)")
        }
    }

    private func editItem(name: String, color: Color, paymentMode: EntityPaymentMode) {
        print("Editing item: \(paymentMode.name)")
        
        // Mettre à jour les propriétés de l'élément dans SwiftData
        PaymentModeManager.shared.configure(with: modelContext)
        PaymentModeManager.shared.update(entity: paymentMode, name: name, color: NSColor.fromSwiftUIColor(color))
        
        // Recharger la liste des éléments
        if let index = modePayments.firstIndex(where: { $0.id == paymentMode.id }) {
            modePayments[index].name = name
            modePayments[index].color = NSColor.fromSwiftUIColor(color) // Assumez que vous stockez une couleur NSColor
        }
    }
    
    private func removeSelectedItem() {
        if let selectedID = selectedItem, let mode = modePayments.first(where: { $0.id == selectedID }) {
            print("Removing item with ID \(selectedID)")
            
            PaymentModeManager.shared.delete(entity: mode)
            selectedItem = nil // Réinitialise la sélection
            
            if let index = modePayments.firstIndex(where: { $0.id == mode.id }) {
                modePayments.remove(at: index)
            }
            
            var count = modePayments.count
            print (count)
            
            let account = CurrrentAccountManager.shared.getAccount()!
            
            loadDatas(for: account)
            count = modePayments.count
            print (count)
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct AddItemDialog: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var selectedColor: Color = .gray
    
    var onAdd: (String, Color) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Payment Mode")
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
                
                Button("OK") {
                    if !name.isEmpty {
                        onAdd(name, selectedColor)
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

struct EditItemDialog: View {
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





