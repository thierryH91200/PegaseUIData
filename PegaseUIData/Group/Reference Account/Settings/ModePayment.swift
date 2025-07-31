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
    
    @State private var modePayments : [EntityPaymentMode] = []

    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID?
    @State private var lastDeletedID: UUID?
    
    var selectedMode: EntityPaymentMode? {
        guard let id = selectedItem else { return nil }
        return modePayments.first(where: { $0.id == id })
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
            if let account = currentAccountManager.currentAccount  {
                Text("Account: \(account.name)")
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
            
           .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in
               printTag("Undo effectué, on recharge les données")
               refreshData()
           }
           .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in
               printTag("Redo effectué, on recharge les données")
               refreshData()
           }

            // Recharge les données lorsqu'un nouveau compte est sélectionné
            .onChange(of: currentAccountManager.currentAccount ) { old, newAccount in
                if newAccount != nil {
                    dataManager.modePayments.removeAll()
                    selectedItem = nil
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
                    Label("Add", systemImage: "plus")
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
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(selectedItem == nil ? Color.gray : Color.green) // Fond gris si désactivé
                        .opacity(selectedItem == nil ? 0.6 : 1) // Opacité réduite si désactivé
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
                Button(action: {
                    delete()
                    setupDataManager()
                })
                {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(selectedItem == nil ? Color.gray : Color.red) // Fond gris si désactivé
                        .opacity(selectedItem == nil ? 0.6 : 1) // Opacité réduite si désactivé
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
                
//                Button(action: {
//                    if let manager = undoManager, manager.canUndo {
//                        selectedItem = nil
//                        lastDeletedID = nil
//                        
//                        manager.undo()
//                        
//                        DispatchQueue.main.async {
//                            refreshData()
//                        }
//                    }
//                }) {
//                    Label("Undo", systemImage: "arrow.uturn.backward")
//                        .frame(minWidth: 100) // Largeur minimale utile
//                        .padding()
//                        .background(canUndo == false ? Color.gray : Color.green)
//                        .opacity(canUndo == false  ? 0.6 : 1)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .buttonStyle(.plain)

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
        DataContext.shared.context = modelContext
        DataContext.shared.undoManager = undoManager
        
        if currentAccountManager.currentAccount != nil {
            if let allData = PaymentModeManager.shared.getAllData() {
                dataManager.modePayments = allData
                modePayments = allData
            } else {
                print("❗️Erreur : getAllData() a renvoyé nil")
            }
        }
    }

    private func delete()
    {
        if let id = selectedItem,
           let modeToDelete = modePayments.first(where: { $0.id == id }) {

            PaymentModeManager.shared.delete(entity: modeToDelete, undoManager: undoManager)
            
            DispatchQueue.main.async {
                selectedItem = nil
                lastDeletedID = nil
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        dataManager.modePayments = PaymentModeManager.shared.getAllData()!
        modePayments = dataManager.modePayments
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
                
                Text(isModeCtreate ? "Add Payment Mode" : "Edit Payment Mode")
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
            newItem = EntityPaymentMode(name: name, color: color)
            modelContext.insert(newItem)
            modePaiementViewManager.modePayments.append(newItem)
        }
        
        newItem.name = name
        newItem.color = NSColor.fromSwiftUIColor(selectedColor)
        newItem.account = CurrentAccountManager.shared.getAccount()!
        
        try? modelContext.save()
    }
}

