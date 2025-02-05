//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

final class ModePaiementDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var modePayments: [EntityPaymentMode]? {
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
       
        do {
            try modelContext?.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct ModePaymentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var dataManager : ModePaiementDataManager

    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID? = nil
    @State private var selectedMode: EntityPaymentMode?
    
    @Query private var modePayments: [EntityPaymentMode] = []
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var modeCreate = false
    
    var body: some View {
        VStack(spacing: 10) {
            
            if let account = dataManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }

            ModePaiementTable(modePayments: dataManager.modePayments ?? [], selection: $selectedItem)
                .frame(height: 300)
            
            .onChange(of: selectedMode) { oldValue, newValue in
                
                if let selectedId = newValue,
                   let selected = modePayments.first(where: { $0.uuid == selectedMode?.uuid }) {
                    selectedItem = selected.id
                    selectedMode = selected
                } else {
                    selectedMode = nil // Désactive l’édition automatique
                    selectedItem = nil

                    print("Aucun élément sélectionné dans ModePaymentView / onCchange")
                }
            }
            .onChange(of: currentAccountManager.currentAccount ) { old, newAccount in
                // Rafraîchir les données` quand le compte change
                if let account = newAccount {
                    dataManager.modePayments = nil
                    dataManager.currentAccount = account
                    selectedMode = nil
                    loadOrCreate(for: account)
                }
            }
            
            .onAppear {

                Task {
                    dataManager.configure(with: modelContext)

                    if let account = currentAccountManager.currentAccount {
                        dataManager.currentAccount = account
                    } else {
                        print("Aucun compte disponible.")
                    }
                    
            
                    PaymentModeManager.shared.configure(with: modelContext)
                    let modePayments = PaymentModeManager.shared.getAllDatas(for: dataManager.currentAccount)
                    dataManager.modePayments = modePayments
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
                .disabled(selectedMode == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action: {
                    removeSelectedItem()
                    refreshData()
                })
                {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedMode == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Utilise tout l'espace parent et aligne en haut
        .padding()
        
        .sheet(isPresented: $isAddDialogPresented) {
            ModePaiementFormView(isPresented: $isAddDialogPresented, mode: $modeCreate, modePaiement: nil)
        }
        .sheet(isPresented: $isEditDialogPresented) {
            ModePaiementFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, modePaiement: selectedMode)
        }

    }
       
    private func removeSelectedItem() {
        guard let selectedMode = selectedMode,
              let selectedMode = modePayments.first(where: { $0.id == selectedMode.id }) else {
            return
        }

        modelContext.delete(selectedMode)
        self.selectedMode = nil
        self.selectedItem = nil

        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la suppression : \(error.localizedDescription)")
        }
    }
    
    func refreshData() {
        guard let account = currentAccountManager.currentAccount else { return }
        dataManager.modePayments = PaymentModeManager.shared.getAllDatas(for: account)
    }
    
    private func loadOrCreate(for account: EntityAccount?) {
        guard let account else { return }
        
        PaymentModeManager.shared.configure(with: modelContext)
        if let existing = PaymentModeManager.shared.getAllDatas(for : account) {
            dataManager.modePayments = existing
        } else {
            let entity = EntityPaymentMode(name: "Test", color: .blue, account: account)
            entity.account = account
            modelContext.insert(entity)
            dataManager.modePayments!.append( entity)
        }
    }
}

struct ModePaiementTable: View {
    
    var modePayments: [EntityPaymentMode]
    @Binding var selection: EntityPaymentMode.ID?
    
    var body: some View {
        
        VStack(spacing: 10) {
            Table(modePayments, selection: $selection) {
                TableColumn("Name", value: \EntityPaymentMode.name)
                TableColumn("Color") { item in
                    Rectangle()
                        .fill(Color(item.color))
                        .frame(width: 40, height: 20)
                }
                TableColumn("Account", value: \EntityPaymentMode.account.name)
                TableColumn("Surname") { paymentMode in
                    Text(paymentMode.account.identity?.surName ?? "Unknown")
                }
                TableColumn("First name")  { paymentMode in
                    Text(paymentMode.account.identity?.name ?? "Unknown")
                }
                TableColumn("Number") { paymentMode in
                    Text(paymentMode.account.initAccount?.codeAccount ?? "Unknown")
                }
            }
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct ModePaiementFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var modePaiementViewManager: ModePaiementDataManager
    
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
        let account = modePaiementViewManager.currentAccount
        
        if let existing = modePaiement {
            newItem = existing
        } else {
            let color = NSColor.fromSwiftUIColor(selectedColor)
            newItem = EntityPaymentMode(name: name, color: color, account: account!)
            modelContext.insert(newItem)
            modePaiementViewManager.modePayments?.append(newItem) // ✅ Ajouter à la liste
        }
        
        newItem.name = name
        newItem.color = NSColor.fromSwiftUIColor(selectedColor)
        newItem.account = CurrentAccountManager.shared.getAccount()!
        
        try? modelContext.save()
    }
}


