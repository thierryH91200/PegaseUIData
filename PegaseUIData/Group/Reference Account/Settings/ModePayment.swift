//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

struct ModePaymentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var dataManager : PaymentModeManager
       
    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID?
    @State private var lastDeletedID: UUID?
    
    var selectedMode: EntityPaymentMode? {
        guard let id = selectedItem else { return nil }
        return dataManager.modePayments.first(where: { $0.id == id })
    }
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    @State private var modeCreate = false
    
    var canUndo : Bool? {
        undoManager?.canUndo ?? false
    }
    var canRedo : Bool? {
        undoManager?.canRedo ?? false
    }
    
    var body: some View {
        VStack(spacing: 10) {
            
            // Affiche le nom du compte courant s'il existe
            if let account = currentAccountManager.getAccount()  {
                Text(String(localized:"Account: \(account.name)",table: "Settings"))
                    .font(.headline)
            }
            
            // Affiche le tableau des modes de paiement
            ModePaiementTable(
                modePayments: dataManager.modePayments,
                selection: $selectedItem)
            .frame(height: 300)
            
            // Mise à jour de l'élément sélectionné
            .onChange(of: selectedItem) { _, newValue in
                
                if let selected = newValue {
                    selectedItem = selected
                } else {
                    selectedItem = nil
                }
            }
            .onDisappear {
                dataManager.modePayments = []
            }

            .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in
                printTag("Undo effectué, on recharge les données")
                refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in
                printTag("Redo effectué, on recharge les données")
                refreshData()
            }
            
            // Recharge les données lorsqu'un nouvel ID de compte est sélectionné
            .onChange(of: currentAccountManager.currentAccountID ) { old, newValue in
                if !newValue.isEmpty {
                    dataManager.modePayments.removeAll()
                    selectedItem = nil
                    refreshData()
                } else {
                    // Cas aucun compte sélectionné si nécessaire
                    dataManager.modePayments.removeAll()
                    selectedItem = nil
                }
            }
            
            // Recharge aussi lorsqu'un nouveau compte résolu est détecté
            .onChange(of: currentAccountManager.getAccount()) { _, newAccount in
                dataManager.modePayments.removeAll()
                selectedItem = nil
                if newAccount != nil {
                    refreshData()
                }
            }
            
            // Charge les données au démarrage de la vue
            .onAppear {
                setupDataManager()
            }
            
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    modeCreate = true
                    
                }) {
                    Label(String(localized:"Add",table: "Settings"), systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Boutons d'action (Ajouter, Modifier, Supprimer)
                Button(action: {
                    isEditDialogPresented = true
                    modeCreate = false
                }) {
                    Label(String(localized:"Edit",table: "Settings"), systemImage: "pencil")
                        .actionButtonStyle(
                            isEnabled: selectedItem != nil,
                            activeColor: .green)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action: {
                    delete()
                    setupDataManager()
                })
                {
                    Label(String(localized:"Delete",table: "Settings"), systemImage: "trash")
                        .actionButtonStyle(
                            isEnabled: selectedItem != nil,
                            activeColor: .red)
                }
                .disabled(selectedItem == nil)
                // Désactive si aucune ligne n'est sélectionnée
                
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
                    Label(String(localized:"Undo",table: "Settings"), systemImage: "arrow.uturn.backward")
                        .actionButtonStyle(
                            isEnabled: canUndo == false,
                            activeColor: .green)
                }
                .disabled(canUndo == false)
                .buttonStyle(.plain)
                
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Utilise tout l'espace parent et aligne en haut
        .padding()
        
        // Formulaire d'ajout et de modification
        .sheet(isPresented: $isAddDialogPresented) {
            ModePaiementFormView(isPresented: $isAddDialogPresented,
                                 isModeCtreate: $modeCreate,
                                 modePaiement: nil)
        }
        .sheet(isPresented: $isEditDialogPresented) {
            ModePaiementFormView(isPresented: $isEditDialogPresented,
                                 isModeCtreate: $modeCreate,
                                 modePaiement: selectedMode)
        }
    }
    
    private func setupDataManager() {
        
        if currentAccountManager.getAccount() != nil {
            let allData = PaymentModeManager.shared.getAllData()
            dataManager.modePayments = allData
            //                dataManager.modePayments = allData
        }
    }
    
    private func delete()
    {
        if let id = selectedItem,
           let modeToDelete = dataManager.modePayments.first(where: { $0.id == id }) {
            PaymentModeManager.shared.delete(entity: modeToDelete, undoManager: undoManager)
            DispatchQueue.main.async {
                selectedItem = nil
                lastDeletedID = nil
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        let allData = PaymentModeManager.shared.getAllData()
        dataManager.modePayments = allData
    }
}

struct ModePaiementTable: View {
    
    var modePayments: [EntityPaymentMode]
    @Binding var selection: EntityPaymentMode.ID?
    
    var body: some View {
        
        VStack(spacing: 10) {
            Table(modePayments, selection: $selection) {
                TableColumn(String(localized:"Name",table: "Settings"), value: \EntityPaymentMode.name)
                TableColumn(String(localized:"Color",table: "Settings")) { item in
                    Rectangle()
                        .fill(Color(item.color))
                        .frame(width: 40, height: 20)
                }
                                        
                TableColumn(String(localized:"Account",table: "Settings"), value: \EntityPaymentMode.account.name)
                TableColumn(String(localized:"Surname",table: "Settings")) { paymentMode in
                    Text(paymentMode.account.identity?.surName ?? "Unknown")
                }
                                                                
                TableColumn(String(localized:"First name",table: "Settings"))  { paymentMode in
                    Text(paymentMode.account.identity?.name ?? String(localized:"Unknown",table: "Settings"))
                }
                TableColumn(String(localized:"Number",table: "Settings")) { paymentMode in
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
    @EnvironmentObject var modePaiementViewManager: PaymentModeManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager

    @Binding var isPresented: Bool
    @Binding var isModeCtreate: Bool
    let modePaiement: EntityPaymentMode?
    
    @State private var name: String = ""
    @State private var selectedColor: Color = .gray
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isModeCtreate ? Color.blue : Color.green)
                .frame(height: 10)
            
            // Contenu principal
            VStack(spacing: 20) {
                
                Text(isModeCtreate ?
                     String(localized:"Add Payment Mode",table: "Settings") :
                    String(localized: "Edit Payment Mode",table: "Settings"))
                    .font(.headline)
                    .padding(.top, 10) // Ajoute un peu d'espace après le bandeau
                
                     TextField(String(localized:"Name",table: "Settings"), text: $name)
                    .textFieldStyle(.roundedBorder)
                
                ColorPicker(String(localized:"Choose the color",table: "Settings"), selection: $selectedColor)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized:"Cancel",table: "Settings")) {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized:"Save",table: "Settings")) {
                        isPresented = false
                        save()
                        dismiss()
                    }
                }
            }
            // Bandeau du bas
            .frame(width: 300)
            
            Rectangle()
                .fill(isModeCtreate ? Color.blue : Color.green)
                .frame(height: 10)
            
                .onAppear {
                    if let modePaiement = modePaiement {
                        name = modePaiement.name
                        selectedColor = Color(modePaiement.color)
                    } else {
                        selectedColor = .blue // Mettre une couleur par défaut sympa
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
            let account = CurrentAccountManager.shared.getAccount()!
            newItem = EntityPaymentMode(account: account, name: name, color: color)
            modelContext.insert(newItem)
            modePaiementViewManager.modePayments.append(newItem)
        }
        
        newItem.name = name
        newItem.color = NSColor.fromSwiftUIColor(selectedColor)
        newItem.account = CurrentAccountManager.shared.getAccount()!
        
        try? modelContext.save()
    }
}

