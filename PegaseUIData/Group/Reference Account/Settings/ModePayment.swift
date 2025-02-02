//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

final class ModePaiementViewManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var modePayments: [EntityPaymentMode]? {
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

struct ModePaymentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var modePaiementViewManager : ModePaiementViewManager

    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID? = nil
    @State private var selectedMode: EntityPaymentMode?
    
    @Query private var modePayments: [EntityPaymentMode] = []
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var modeCreate = false
    
    var body: some View {
        VStack(spacing: 10) {
            Table(modePaiementViewManager.modePayments ?? [], selection: $selectedItem) {
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
            .onChange(of: selectedItem) { oldValue, newValue in
                selectedMode = nil // Désactive l’édition automatique
                selectedItem = nil
                
                if let selectedId = newValue,
                   let selected = modePayments.first(where: { $0.id == selectedId }) {
                    selectedMode = selected
                    selectedItem = selected.id
                } else {
                    print("Aucun élément sélectionné dans ModePaymentView / onCchange")
                }
            }
            .onChange(of: currentAccountManager.currentAccount ) { old, newAccount in
                // Rafraîchir les données` quand le compte change
                if let account = newAccount {
                    modePaiementViewManager.modePayments = nil
                    modePaiementViewManager.currentAccount = account
                    selectedMode = nil
                    selectedItem = nil
                    loadOrCreate(for: account)
                }
            }
            
            .onAppear {
                Task {
                    
                    if let account = currentAccountManager.currentAccount {
                        modePaiementViewManager.currentAccount = account
                    } else {
                        print("Aucun compte disponible.")
                    }
                    
                    // Créer un nouvel enregistrement si la base de données est vide
                    if modePaiementViewManager.modePayments == nil {
                        if let account = CurrentAccountManager.shared.getAccount() {
                            modePaiementViewManager.currentAccount = account
                        } else {
                            print("Aucun compte disponible.")
                        }
                        ChequeBookManager.shared.configure(with: modelContext)
                        let modePayments = PaymentModeManager.shared.getAllDatas(for:  modePaiementViewManager.currentAccount)
                        modePaiementViewManager.modePayments = modePayments
                        
                        if modePayments == nil {
                            
                            let entity = EntityPaymentMode(name: "test", color: .blue, account: nil)
                            modePaiementViewManager.modePayments!.append( entity   )
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
        
        .sheet(isPresented: $isEditDialogPresented) {
            ModePaiementFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, modePaiement: nil)
        }
        .sheet(isPresented: $isAddDialogPresented) {
            ModePaiementFormView(isPresented: $isAddDialogPresented, mode: $modeCreate, modePaiement: nil)
        }
    }
       
    private func removeSelectedItem() {
        //        modelContext.delete(selectedItem!)
        //        if selectedItem == selectedItem!.id {
        //            selectedItem = nil
        //        }
        //        try? modelContext.save()
    }
    
    private func loadOrCreate(for account: EntityAccount?) {
        guard let account else { return }
        
        PaymentModeManager.shared.configure(with: modelContext)
        if let existing = PaymentModeManager.shared.getAllDatas(for : account) {
            modePaiementViewManager.modePayments = existing
        } else {
            let entity = EntityPaymentMode(name: "Test", color: .blue)
            entity.account = account
            modelContext.insert(entity)
            modePaiementViewManager.modePayments!.append( entity)
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct ModePaiementFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var mode: Bool
    let modePaiement: EntityPaymentMode?
    @State private var name: String = ""
    @State private var selectedColor: Color = .gray
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(mode ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                
                Text(mode ? "Add Payment Mode" : "Edit Payment Mode")
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                ColorPicker("Choose the color", selection: $selectedColor)
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
                .fill(mode ? Color.blue : Color.green)
                .frame(height: 10)
            
                .onAppear {
                    if let modePaiement = modePaiement {
                        name = modePaiement.name
                        selectedColor = Color(modePaiement.color)
                    }
                }
        }
    }
    
    private func save() {
        let newItem: EntityPaymentMode
        
        if let existing = modePaiement {
            newItem = existing
        } else {
            let color = NSColor.fromSwiftUIColor(selectedColor)
            newItem = EntityPaymentMode(name: name, color: color)
            modelContext.insert(newItem)
        }
        
        newItem.name = name
        newItem.color = NSColor.fromSwiftUIColor(selectedColor)
        newItem.account = CurrentAccountManager.shared.getAccount()!
        
        try? modelContext.save()
    }
}


