//
//  SchedulerView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI

struct SchedulerView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        Scheduler()
            .padding()
            .task {
                await performFalseTask()
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
    
}


struct Scheduler: View {
    
    @Environment(\.modelContext) private var modelContext
    
    var account = CurrrentAccountManager.shared.getAccount()!
    @State private var scheduler: [EntitySchedule] = []
    
    @State private var selectedItem: EntitySchedule.ID?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false // Nouveau état pour afficher le dialog d'édition
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Format de date (ex. "22 janv. 2025")
        formatter.timeStyle = .none  // Pas d'heure
        return formatter
    }()

    
    var body: some View {
        VStack(spacing: 10) {
            Text("Account: \(account.name)")
                .font(.headline)
            
            Table(scheduler, selection: $selectedItem) {
                
                TableColumn("Value Date") { (item: EntitySchedule) in
                    let dateValeur = item.dateValeur  // Vérifiez si la date n'est pas nulle
                        Text(dateFormatter.string(from: dateValeur))
                }
                
                TableColumn("Start Date") { (item: EntitySchedule) in
                    let dateDebut = item.dateDebut  // Vérifiez si la date n'est pas nulle
                        Text(dateFormatter.string(from: dateDebut))
                }
                
                TableColumn("End Date") { (item: EntitySchedule) in
                    let dateFin = item.dateFin // Vérifiez si la date n'est pas nulle
                        Text(dateFormatter.string(from: dateFin))
                }
                
                TableColumn( "Frequency") { (item: EntitySchedule) in
                    Text(String(item.frequence))
                }
                
                TableColumn( "Comment") { (item: EntitySchedule) in
                    Text(item.libelle)
                }
                
                TableColumn( "Next") { (item: EntitySchedule) in
                    Text(String(item.nextOccurence))
                }
                
                TableColumn( "Occurence") { (item: EntitySchedule) in
                    Text(String(item.occurence))
                }
                
                TableColumn( "Name") { item in
                    Text(item.account!.identity?.name ?? "")
                }
                
                TableColumn( "Number") { item in
                    Text(item.account!.initAccount?.codeAccount ?? "")
                }
            }
            .onAppear {
                Task {
                    SchedulerManager.shared.configure(with: modelContext)
                    scheduler = SchedulerManager.shared.getAllDatas(for: account)
                    
                    if let firstItem = scheduler.first {
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
        SchedulerManager.shared.configure(with: modelContext)
        let entity = SchedulerManager.shared.create(account: account, name: name)
        
        modelContext.insert(entity) // Ajoutez l'entité au contexte
        
        do {
            // Sauvegardez le contexte pour persister les modifications
            try modelContext.save()
            print("Cheque book added successfully.")
        } catch {
            print("Erreur lors de l'ajout de l'entité : \(error)")
        }
    }
    
    private func editItem(name: String, occurence: Int16, entity: EntitySchedule) {
        print("Editing item: \(entity.libelle)")
        
        // Mettre à jour les propriétés de l'élément dans SwiftData
        SchedulerManager.shared.configure(with: modelContext)
        SchedulerManager.shared.update(entity: entity, name: name)
        
        // Recharger la liste des éléments
        if let index = scheduler.firstIndex(where: { $0.id == entity.id }) {
            scheduler[index].libelle = name
            scheduler[index].occurence = occurence
        }
    }
    
    private func removeSelectedItem() {
        
        if let selectedID = selectedItem, let mode = scheduler.first(where: { $0.id == selectedID }) {
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
struct AddItemDialogCheck: View {
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var numPremier: String = ""
    @State private var numSuivant: String = ""
    @State private var prefix: String = ""
    
    var onAdd: (String, String, String, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Payment Mode")
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

struct EditItemDialogCheck: View {
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

