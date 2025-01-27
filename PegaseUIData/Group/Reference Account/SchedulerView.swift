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
    
    @ObservedObject var accountManager = CurrentAccountManager.shared

    var account = CurrentAccountManager.shared.getAccount()!
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
                
                TableColumn( "Amount") { (item: EntitySchedule) in
                    Text(String(item.amount))
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
                        print("No items in Scheduler")
                    }
                }
            }
            .frame(height: 300)
            .sheet(isPresented: $isAddDialogPresented) {
                AddItemDialogSchedule(isPresented: $isAddDialogPresented) { newScheduler in
                    // Ajoute le nouvel élément à la liste
                    scheduler.append(newScheduler)
                }
            }
            
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
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
            Spacer()
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
struct AddItemDialogSchedule: View {
    @Binding var isPresented: Bool
    
    @State private var amount: String = ""
    @State private var dateValeur: Date = Date()
    @State private var dateDebut: Date = Date()
    @State private var dateFin: Date = Date()
    @State private var frequence: String = ""
    @State private var libelle: String = ""
    @State private var nextOccurence: String = ""
    @State private var occurence: String = ""
    @State private var frequencytype: String = ""
    
    var onAdd: (EntitySchedule) -> Void // Callback pour transmettre l'élément ajouté
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Scheduler")
                .font(.headline)
            
            HStack {
                Text("Amount")
                    .frame(width: 100, alignment: .leading)
                TextField("Amount", text: $amount)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Value Date")
                    .frame(width: 100, alignment: .leading) // Fixe la largeur et aligne à gauche
                    .background(Color.clear) // Optionnel : utile pour déboguer l'espace réservé
                    .padding(.leading, 0) // Supprime tout décalage potentiel
                DatePicker(" ", selection: $dateValeur, displayedComponents: .date)
            }
            
            HStack {
                Text("start Date")
                    .frame(width: 100, alignment: .leading)
                DatePicker(" ", selection: $dateDebut, displayedComponents: .date)
            }
            
            HStack {
                Text("end Date")
                    .frame(width: 100, alignment: .leading)
                DatePicker("", selection: $dateFin, displayedComponents: .date)
            }
            
            HStack {
                Text("Frequency")
                    .frame(width: 100, alignment: .leading)
                TextField("Frequency", text: $frequence)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Comment")
                    .frame(width: 100, alignment: .leading)
                TextField("Comment", text: $libelle)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("next Occurence")
                    .frame(width: 100, alignment: .leading)
                TextField("next Occurence", text: $nextOccurence)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Occurence")
                    .frame(width: 100, alignment: .leading)
                TextField("Occurence", text: $occurence)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Text("Frequency type")
                    .frame(width: 100, alignment: .leading)
                TextField("Frequency type", text: $frequencytype)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("OK") {
                    if let frequenceValue = Int16(frequence),
                       let nextOccurenceValue = Int16(nextOccurence),
                       let occurenceValue = Int16(occurence),
                       let frequencyTypeValue = Int16(frequencytype),
                       let amount = Double(amount) {
                        
                        // Crée une nouvelle instance d'EntitySchedule
                        let newSchedule = EntitySchedule(
                            amount: amount,
                            dateValeur: dateValeur.noon,
                            dateDebut: dateDebut,
                            dateFin: dateFin,
                            frequence: frequenceValue,
                            libelle: libelle,
                            nextOccurence: nextOccurenceValue,
                            occurence: occurenceValue,
                            typeFrequence: frequencyTypeValue,
                            account: CurrentAccountManager.shared.getAccount()!
                        )
                        
                        // Appelle le callback avec le nouvel élément
                        onAdd(newSchedule)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(libelle.isEmpty) // Désactive le bouton si le nom est vide
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
            Text("Edit Scheduler")
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

