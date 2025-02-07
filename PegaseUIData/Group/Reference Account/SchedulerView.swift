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
            guard modelContext != nil else { return }
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
    @EnvironmentObject var dataManager : SchedulerDataManager

    @ObservedObject var accountManager = CurrentAccountManager.shared

    @State private var schedulers: [EntitySchedule] = []
    
    @State private var selectedItem: EntitySchedule.ID?
    @State private var selected: EntitySchedule?
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
            if let account = dataManager.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            
            SchedulerTable(schedulers: dataManager.schedulers ?? [], selection: $selectedItem)
                .frame(height: 300)

            .onAppear {
                setupDataManager()
            }
            
            .onChange(of: selectedItem) { oldValue, newValue in

                if let selected = newValue {
                    selectedItem = selected
                    if let schedulers = dataManager.schedulers {
                        selectedSchedule = schedulers.first(where: { $0.id == selected })
                    }
                } else {
                    selectedSchedule = nil // Désactive l’édition automatique
                    selectedItem = nil
                }
            }
            .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                
                if let account = newAccount {
                    dataManager.schedulers = nil
                    dataManager.currentAccount = account
                    selectedSchedule = nil
                    selectedItem = nil
                    selected = nil
                    refreshData()
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
                    affectSelect()
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
                }) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(selectedItem == nil ? Color.gray : Color.red) // Fond gris si désactivé
                        .opacity(selectedItem == nil ? 0.6 : 1) // Opacité réduite si désactivé
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
            Spacer()
        }
        
        .sheet(isPresented: $isAddDialogPresented) {
            SchedulerFormView(isPresented: $isAddDialogPresented, mode: $modeCreate, scheduler: $selected)
        }
        
        .sheet(isPresented: $isEditDialogPresented) {
            SchedulerFormView(isPresented: $isEditDialogPresented, mode: $modeCreate, scheduler: $selectedSchedule)
        }
    }
    
    private func affectSelect () {
        if let schedulers = dataManager.schedulers {
            selectedSchedule = schedulers.first(where: { $0.id == selectedItem })
        }
    }
    
    private func setupDataManager() {
        SchedulerManager.shared.configure(with: modelContext)
        dataManager.configure(with: modelContext)

        if let account = currentAccountManager.currentAccount {
            dataManager.currentAccount = account
            dataManager.schedulers = SchedulerManager.shared.getAllDatas()
        }
    }
    
    private func delete() {
        
        if let modeToDelete = selectedSchedule {
            modelContext.delete(modeToDelete)  // Suppression de l'élément du contexte
            selectedSchedule = nil  // Réinitialisation de la sélection
            selectedItem = nil
            try? modelContext.save()  // Sauvegarde du contexte après suppression
            refreshData()
        }
    }
    private func refreshData() {
        dataManager.schedulers = SchedulerManager.shared.getAllDatas()
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
    @EnvironmentObject var schedulerDataManager: SchedulerDataManager

    @Binding var isPresented: Bool
    @Binding var mode: Bool
    
    @Binding var scheduler: EntitySchedule?
        
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
        .onChange(of: scheduler) { oldValue, newValue in
            print("scheduler a changé : \(oldValue?.libelle ?? "nil") -> \(newValue?.libelle ?? "nil")")
        }
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
                nextOccurence = String(scheduler.nextOccurence)
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

