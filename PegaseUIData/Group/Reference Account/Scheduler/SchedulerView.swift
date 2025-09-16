//
//  SchedulerView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import AppKit
import SwiftUI
import SwiftData


struct SchedulerView: View {
    
    @StateObject private var dataManager = SchedulerManager()
    
    @Binding var isVisible: Bool
    
    var body: some View {
        
        
        Scheduler( selectedType: "")
            .environmentObject(dataManager)
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
    @Environment(\.undoManager)  private var undoManager
    
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var dataManager : SchedulerManager
        
    @State private var schedulers: [EntitySchedule] = []
    @State private var upcoming: [EntitySchedule] = []

    @State private var selectedItem: EntitySchedule.ID?
    @State private var lastDeletedID: UUID?
    
    var selectedSchedule: EntitySchedule? {
        guard let id = selectedItem else { return nil }
        return schedulers.first(where: { $0.id == id })
    }
    
    @State private var frequenceType     : [String]    = []
    @State var selectedType     : String
    
    var canUndo : Bool? {
        undoManager?.canUndo ?? false
    }
    var canRedo : Bool? {
        undoManager?.canRedo ?? false
    }
    
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false

    @State private var isModeCreate = false
        
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Format de date (ex. "22 janv. 2025")
        formatter.timeStyle = .none  // Pas d'heure
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 2) {
            if let account = CurrentAccountManager.shared.getAccount() {
                Text("Account: \(account.name)")
                    .font(.headline)
                    .padding(.bottom, 0)
            }
            SchedulerTable(schedulers: dataManager.schedulers, selection: $selectedItem)
                .background(Color(nsColor: .windowBackgroundColor))
                .tableStyle(.bordered)
                .frame(height: 300)
                .padding(.top, 0)
            
                .onAppear {
                    setupDataManager()
                }
                .onDisappear {
                    schedulers.removeAll()
                    upcoming.removeAll()
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in
                    printTag("Undo effectué, on recharge les données")
                    refreshData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in
                    printTag("Redo effectué, on recharge les données")
                    refreshData()
                }
                .onChange(of: schedulers) { _, _ in
                    if let restoredID = lastDeletedID,
                       schedulers.contains(where: { $0.id == restoredID }) {
                        selectedItem = restoredID
                        lastDeletedID = nil
                    }
                }
            
                .onChange(of: selectedItem) { oldValue, newValue in
                    if let selected = newValue {
                        schedulers = dataManager.schedulers
                        selectedItem = selected
                        
                    } else {
                        selectedItem = nil
                    }
                }
            
                .onChange(of: currentAccountManager.currentAccountID) { old, newValue in
                    
                    if newValue.isEmpty {
                        dataManager.schedulers.removeAll()
                        selectedItem = nil
//                      lastDeletedID = nil

                        refreshData()
                    }
                }
            
                .onChange(of: dataManager.schedulers) { old, new in
                    selectedItem = nil
                    schedulers = dataManager.schedulers
                    upcoming = dataManager.schedulers.filter {
                        $0.dateValeur >= Date()
                    }.sorted { $0.dateValeur < $1.dateValeur }
                }
            
                .onReceive(NotificationCenter.default.publisher(for: .didSelectScheduler)) { notif in
                    if let scheduler = notif.object as? EntitySchedule {
                        selectedItem = scheduler.id
                    }
                }
            
            HStack {
                Button(action: {
                    isAddDialogPresented = true
                    isModeCreate = true
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
                    isModeCreate = false
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
                
                Button(action: {
                    if let manager = undoManager, manager.canUndo {
                        selectedItem = nil
                        lastDeletedID = nil

                        undoManager?.undo()
                        
                        DispatchQueue.main.async {
                            refreshData()
                        }
                    }
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background(canUndo == false ? Color.gray : Color.green)
                        .opacity(canUndo == false  ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    if let manager = undoManager, manager.canRedo {
                        selectedItem = nil
                        lastDeletedID = nil

                        manager.redo()

                        DispatchQueue.main.async {
                            refreshData()
                        }
                    }
                }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                        .frame(minWidth: 100) // Largeur minimale utile
                        .padding()
                        .background( canRedo == false ? Color.gray : Color.orange)
                        .opacity( canRedo  == false ? 0.6 : 1)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            UpcomingRemindersView(upcoming: upcoming)
            Spacer()
        }
        
        .sheet(isPresented: $isAddDialogPresented, onDismiss: {setupDataManager()}) {
            SchedulerFormView(isPresented: $isAddDialogPresented,
                              isModeCreate: $isModeCreate,
                              scheduler: selectedSchedule,
                              selectedTypeIndex: indexForSelectedType())
        }
        
        .sheet(isPresented: $isEditDialogPresented, onDismiss: {setupDataManager()}) {
            SchedulerFormView(isPresented: $isEditDialogPresented,
                              isModeCreate: $isModeCreate,
                              scheduler: selectedSchedule,
                              selectedTypeIndex: indexForSelectedType())
        }
    }
    
    private func affectSelect () {
        schedulers = dataManager.schedulers
        //        selectedSchedule = schedulers.first(where: { $0.id == selectedItem })
    }
    
    private func setupDataManager() {
                
        if currentAccountManager.getAccount() != nil {
            if let allData = SchedulerManager.shared.getAllData() {
                dataManager.schedulers = allData
                schedulers = allData
            } else {
                print("❗️Erreur : getAllData() a renvoyé nil")
            }
        }
    }
    
    private func delete() {
        
        if let id = selectedItem,
           let item = schedulers.first(where: { $0.id == id }) {
            
            lastDeletedID = item.id
            
            SchedulerManager.shared.delete(entity: item, undoManager: undoManager)
            _ = SchedulerManager.shared.getAllData()
            DispatchQueue.main.async {
                selectedItem = nil
                lastDeletedID = nil
                
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        dataManager.schedulers = SchedulerManager.shared.getAllData() ?? []
        schedulers = dataManager.schedulers
    }
    
    private func indexForSelectedType() -> Int {
        let types = ["Day", "Week", "Month", "Year"]
        return types.firstIndex(of: selectedType) ?? 2 // Retourne 2 (Month) par défaut
    }
}

struct SchedulerTable: View {
    
    var schedulers: [EntitySchedule]
    @Binding var selection: EntitySchedule.ID?
    
    @State private var hoveredItemID: UUID? // Track hovered row
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        
        Table(schedulers, selection: $selection) {
            Group {
                TableColumn("Value Date") { (item: EntitySchedule) in
                    Text(dateFormatter.string(from: item.dateValeur))
                }
                TableColumn("Start Date") { (item: EntitySchedule) in
                    Text(dateFormatter.string(from: item.dateValeur))
                }
                TableColumn("End Date") { (item: EntitySchedule) in
                    Text(dateFormatter.string(from: item.dateFin))
                }
                TableColumn("Amount") { (item: EntitySchedule) in
                    Text(String(item.amount))
                }
                TableColumn("Frequency") { (item: EntitySchedule) in
                    Text(String(item.frequence))
                }
                TableColumn("Comment") { (item: EntitySchedule) in
                    Text(item.libelle)
                }
                TableColumn("Next") { (item: EntitySchedule) in
                    Text(String(item.nextOccurrence))
                }
                TableColumn("Occurrence") { (item: EntitySchedule) in
                    Text(String(item.occurrence))
                }
            }
            Group {
                TableColumn("Mode") { (item: EntitySchedule) in
                    Text(item.paymentMode?.name ?? "N/A")
                }
                TableColumn("Rubric") { (item: EntitySchedule) in
                    Text(item.category?.rubric?.name ?? "N/A")
                }
                TableColumn("Category") { (item: EntitySchedule) in
                    Text(item.category?.name ?? "")
                }
                TableColumn("Name") { (item: EntitySchedule) in
                    Text(item.account.name)
                }
                TableColumn("Number") { (item: EntitySchedule) in
                    Text(item.account.initAccount?.codeAccount ?? "")
                }
            }
        }
    }
}

