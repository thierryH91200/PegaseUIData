//
//  SchedulerView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import SwiftData

final class SchedulerDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var schedulers: [EntitySchedule]? {
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

struct SchedulerView: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var schedulerDataManager = SchedulerDataManager()

    @Binding var isVisible: Bool
    
    var body: some View {
        Scheduler()
            .environmentObject(schedulerDataManager)
            .environmentObject(currentAccountManager)

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
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var schedulerDataManager : SchedulerDataManager

    @ObservedObject var accountManager = CurrentAccountManager.shared

    @State private var schedulers: [EntitySchedule] = []
    
    @State private var selectedItem: EntitySchedule.ID?
    @State private var selectedSchedule: EntitySchedule?
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false // Nouveau état pour afficher le dialog d'édition
    @State private var modeCreate = false

    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Format de date (ex. "22 janv. 2025")
        formatter.timeStyle = .none  // Pas d'heure
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            if let account = schedulerDataManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            SchedulerTable(schedulers: schedulers, selection: $selectedItem)
            
            .onAppear {
                if let account = currentAccountManager.currentAccount {
                    schedulerDataManager.currentAccount = account
                }
                
                // Créer un nouvel enregistrement si la base de données est vide
                if schedulerDataManager.schedulers == nil {
                    if let account = CurrentAccountManager.shared.getAccount() {
                        schedulerDataManager.currentAccount = account
                    } else {
                        print("Aucun compte disponible.")
                    }
                    SchedulerManager.shared.configure(with: modelContext)
                    let schedulers = SchedulerManager.shared.getAllDatas()
                    schedulerDataManager.schedulers = schedulers
                    
                    if schedulers == nil {
                        
                        let newEntity = EntitySchedule()
                        schedulerDataManager.schedulers!.append( newEntity   )
                        modelContext.insert(newEntity)
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                selectedSchedule = nil // Désactive l’édition automatique
                
                if let selectedId = newValue,
                   let selected = schedulers.first(where: { $0.id == selectedId }) {
                    selectedSchedule = selected
                }

            }
            .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                
                if let account = newAccount {
                    schedulerDataManager.schedulers = nil
                    schedulerDataManager.currentAccount = account
                    
                    loadOrCreate(for: account)
                }
            }
            .frame(height: 300)
            
            .sheet(isPresented: $isAddDialogPresented) {
                SchedulerFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, scheduler: selectedSchedule)
            }
            .sheet(isPresented: $isEditDialogPresented) {
                SchedulerFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, scheduler: nil)
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
                
                Button(action: {
                    removeSelectedItem(selectedSchedule!)
                }) {
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
    
    
    private func loadOrCreate(for account: EntityAccount) {
        
        BankStatementManager.shared.configure(with: modelContext)
        if let existing = SchedulerManager.shared.getAllDatas() {
            schedulerDataManager.schedulers = existing
        } else {
            let entity = EntitySchedule()
            entity.account = account
            modelContext.insert(entity)
            schedulerDataManager.schedulers!.append( entity)
        }
    }
    
    private func removeSelectedItem(_ scheduler: EntitySchedule) {
        
        modelContext.delete(scheduler)
        if selectedItem == scheduler.id {
            selectedItem = nil
        }
        try? modelContext.save()
    }
}

struct SchedulerTable: View {
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var schedulers: [EntitySchedule]
    @Binding var selection: UUID?

    var body: some View {
        
        Table(schedulers, selection: $selection) {
            
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
                Text(item.account.identity?.name ?? "")
            }
            
            TableColumn( "Number") { item in
                Text(item.account.initAccount?.codeAccount ?? "")
            }
        }
    }
}

// Vue pour la boîte de dialogue d'ajout
struct SchedulerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var mode: Bool
    let scheduler: EntitySchedule?
    @State private var amount: String = ""
    @State private var dateValeur: Date = Date()
    @State private var dateDebut: Date = Date()
    @State private var dateFin: Date = Date()
    @State private var frequence: String = ""
    @State private var libelle: String = ""
    @State private var nextOccurence: String = ""
    @State private var occurence: String = ""
    @State private var frequencytype: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(mode ? "Add Scheduler" : "Edit Scheduler")
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
                DatePicker("", selection: $dateValeur, displayedComponents: .date)
            }
            
            HStack {
                Text("Start Date")
                    .frame(width: 100, alignment: .leading)
                DatePicker("", selection: $dateDebut, displayedComponents: .date)
            }
            
            HStack {
                Text("End Date")
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
                Text("Next occurence")
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
        }
        .frame(width: 300)
        .padding()
        .navigationTitle(scheduler == nil ? "New scheduler" : "Edit scheduler")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
            }
        }
        .onAppear {
            if let scheduler = scheduler {
                amount = String(scheduler.amount)
                dateValeur = scheduler.dateValeur
                dateDebut = scheduler.dateDebut
                dateFin = scheduler.dateFin
                frequence = String(scheduler.frequence)
                libelle = scheduler.libelle
                occurence = String(scheduler.occurence)
                frequencytype = String(scheduler.typeFrequence)
            }
        }

    }

    private func save() {
        
        let newItem: EntitySchedule
        
        if let existingStatement = scheduler {
            newItem = existingStatement
        } else {
            newItem = EntitySchedule()
            modelContext.insert(newItem)
        }
        if let frequence = Int16(frequence),
           let nextOccurence = Int16(nextOccurence),
           let occurence = Int16(occurence),
           let frequencyTypeValue = Int16(frequencytype),
           let amount = Double(amount) {
            
            newItem.amount = amount
            newItem.dateValeur = dateValeur.noon
            newItem.dateDebut = dateDebut.noon
            newItem.dateFin = dateFin.noon
            newItem.frequence = frequence
            newItem.libelle = libelle
            newItem.nextOccurence = nextOccurence
            newItem.occurence = occurence
            newItem.typeFrequence = frequencyTypeValue
            newItem.account = CurrentAccountManager.shared.getAccount()!
            
            try? modelContext.save()
        }
    }
}

