//
//  SchedulerView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import AppKit
import SwiftUI
import SwiftData
 

final class SchedulerDataManager: ObservableObject {
    @Published var schedulers: [EntitySchedule] = [] {
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
    
    func selectScheduler(_ scheduler: EntitySchedule) {
        NotificationCenter.default.post(name: .didSelectScheduler, object: scheduler)
    }
}

struct SchedulerView: View {
    
    @StateObject private var schedulerDataManager = SchedulerDataManager()
    
    @Binding var isVisible: Bool
    
    var body: some View {
        Scheduler( selectedType: "")
            .environmentObject(schedulerDataManager)
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
    @State private var upcoming: [EntitySchedule] = []

    @State private var frequenceType     : [String]    = []
    @State var selectedType     : String

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
            if let account = CurrentAccountManager.shared.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            
            SchedulerTable(schedulers: dataManager.schedulers, selection: $selectedItem)
                .frame(height: 300)
            
                .onAppear {
                    setupDataManager()
                }
            
                .onChange(of: selectedItem) { oldValue, newValue in
                    if let selected = newValue {
                        selectedItem = selected
                        let schedulers = dataManager.schedulers
                        selectedSchedule = schedulers.first(where: { $0.id == selected })
                    } else {
                        selectedSchedule = nil // Désactive l’édition automatique
                        selectedItem = nil
                    }
                }
                .onChange(of: CurrentAccountManager.shared.currentAccount) { old, newAccount in
                    
                    if newAccount != nil {
                        dataManager.schedulers = []
                        selectedSchedule = nil
                        selectedItem = nil
                        selected = nil
                        refreshData()
                    }
                }
                .onChange(of: dataManager.schedulers) { old, new in
                    selectedSchedule = nil
                    selectedItem = nil
                    selected = nil
                    upcoming = dataManager.schedulers.filter {
                        $0.dateValeur >= Date()
                    }.sorted { $0.dateValeur < $1.dateValeur }
                }
                .onReceive(NotificationCenter.default.publisher(for: .didSelectScheduler)) { notif in
                    if let scheduler = notif.object as? EntitySchedule {
                        selectedItem = scheduler.id
                        selectedSchedule = scheduler
                        selected = scheduler
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
            UpcomingRemindersView(upcoming: upcoming)
            Spacer()
        }
        
        .sheet(isPresented: $isAddDialogPresented) {
            SchedulerFormView(isPresented: $isAddDialogPresented, isModeCreate: $modeCreate, scheduler: $selected, selectedTypeIndex: indexForSelectedType())
        }
        
        .sheet(isPresented: $isEditDialogPresented) {
            SchedulerFormView(isPresented: $isEditDialogPresented, isModeCreate: $modeCreate, scheduler: $selectedSchedule, selectedTypeIndex: indexForSelectedType())
        }
    }
    
    private func affectSelect () {
        let schedulers = dataManager.schedulers
        selectedSchedule = schedulers.first(where: { $0.id == selectedItem })
    }
    
    private func setupDataManager() {
        SchedulerManager.shared.configure(with: modelContext)
        dataManager.configure(with: modelContext)
        
        if currentAccountManager.currentAccount != nil {
            dataManager.schedulers = SchedulerManager.shared.getAllDatas()!
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
        dataManager.schedulers = SchedulerManager.shared.getAllDatas()!
    }
    
    private func indexForSelectedType() -> Int {
        let types = ["Day", "Week", "Month", "Year"]
        return types.firstIndex(of: selectedType) ?? 2 // Retourne 2 (Month) par défaut
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
        
        ScrollViewReader { proxy in
            Table(schedulers, selection: $selection) {
                //                Group {
                TableColumn("Value Date") { item in
                    Text(dateFormatter.string(from: item.dateValeur))
                        .id(item.id)
                }
                TableColumn("Start Date") { item in
                    Text(dateFormatter.string(from: item.dateDebut))
                }
                TableColumn("End Date") { item in
                    Text(dateFormatter.string(from: item.dateFin))
                }
                TableColumn("Amount") { item in
                    Text(String(item.amount))
                }
                TableColumn("Frequency") { item in
                    Text(String(item.frequence))
                }
                TableColumn("Comment") { item in
                    Text(item.libelle)
                }
                TableColumn("Next") { item in
                    Text(String(item.nextOccurence))
                }
                TableColumn("Occurence") { item in
                    Text(String(item.occurence))
                }
                //                }
                //                Group {
                TableColumn("Mode") { item in
                    Text(String(item.paymentMode?.name ?? "N/A"  ))
                }
                //                    TableColumn("Rubric") { item in
                //                        Text(String(item.category?.rubric?.name ?? "N/A"))
                //                    }
                TableColumn("Category") { item in
                    Text(String(item.category?.name  ?? "N/A"))
                }
                //                    TableColumn("Name") { item in
                //                        Text(item.account.identity?.name ?? "")
                //                    }
                //                    TableColumn("Number") { item in
                //                        Text(item.account.initAccount?.codeAccount ?? "")
                //                    }
                //                }
            }
            .onChange(of: selection) { old, newID in
                if let newID = newID {
                    withAnimation {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
    }
}
