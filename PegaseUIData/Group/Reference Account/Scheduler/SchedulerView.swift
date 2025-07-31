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
            if let account = CurrentAccountManager.shared.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
                    .padding(.bottom, 0)
            }
            SchedulerTable(schedulers: dataManager.schedulers, selection: $selectedItem)
                .background(Color.red)
                .tableStyle(.bordered)
                .frame(height: 300)
                .padding(.top, 0)
            
                .onAppear {
                    setupDataManager()
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
            
                .onChange(of: CurrentAccountManager.shared.currentAccount) { old, newAccount in
                    
                    if newAccount != nil {
                        dataManager.schedulers.removeAll()
                        selectedItem = nil
//                        lastDeletedID = nil

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
        DataContext.shared.context = modelContext
        DataContext.shared.undoManager = undoManager
        
        if currentAccountManager.currentAccount != nil {
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
        dataManager.schedulers = SchedulerManager.shared.getAllData()!
        schedulers = dataManager.schedulers
    }
    
    private func indexForSelectedType() -> Int {
        let types = ["Day", "Week", "Month", "Year"]
        return types.firstIndex(of: selectedType) ?? 2 // Retourne 2 (Month) par défaut
    }
}

struct SchedulerTable: View {
    
    var schedulers: [EntitySchedule]
    @Binding var selection: UUID?
    @State private var hoveredItemID: UUID? // Track hovered row
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        ScrollView([.vertical]) {
            LazyVStack(alignment: .leading, spacing: 4) {
                headerView()
                Divider()
                rowsView()
            }
            .padding(.horizontal)
        }
        .frame(minHeight: 300)
        .background(Color.white)
        
    }
    
    @ViewBuilder
    private func rowsView() -> some View {
        ForEach(Array(schedulers.enumerated()), id: \.element.id) { index, item in
            let isSelected = item.id == selection
            let isHovered = item.id == hoveredItemID
            let baseColor = index.isMultiple(of: 2) ? Color.white : Color(nsColor: .controlBackgroundColor)
            let rowColor = isSelected ? Color.accentColor.opacity(0.2)
            : isHovered ? Color.gray.opacity(0.1)
            : baseColor
            
            rowView(item: item)
                .background(rowColor)
                .contentShape(Rectangle())
                .onTapGesture {
                    if selection == item.id {
                        selection = nil
                    } else {
                        selection = item.id
                    }
                }
                .tag(item.id)
                .onHover { hovering in
                    hoveredItemID = hovering ? item.id : nil
                }
        }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            headerGroup1()
            headerGroup2()
            headerGroup3()
        }
    }
    
    @ViewBuilder
    private func headerGroup1() -> some View {
        Group {
            Text("Value Date").bold().frame(minWidth: 100, alignment: .leading)
            Text("Start Date").bold().frame(minWidth: 100, alignment: .leading)
            Text("End Date").bold().frame(minWidth: 100, alignment: .leading)
            Text("Amount").bold().frame(minWidth: 100, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func headerGroup2() -> some View {
        Group {
            Text("Frequency").bold().frame(minWidth: 100, alignment: .leading)
            Text("Comment").bold().frame(minWidth: 120, alignment: .leading)
            Text("Next").bold().frame(minWidth: 100, alignment: .leading)
            Text("Occurrence").bold().frame(minWidth: 100, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func headerGroup3() -> some View {
        Group {
            Text("Mode").bold().frame(minWidth: 100, alignment: .leading)
            Text("Rubric").bold().frame(minWidth: 100, alignment: .leading)
            Text("Category").bold().frame(minWidth: 100, alignment: .leading)
            Text("Name").bold().frame(minWidth: 120, alignment: .leading)
            Text("Number").bold().frame(minWidth: 100, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func rowView(item: EntitySchedule) -> some View {
        HStack {
            rowGroup1(item)
            rowGroup2(item)
            rowGroup3(item)
        }
    }
    
    @ViewBuilder
    private func rowGroup1(_ item: EntitySchedule) -> some View {
        Group {
            Text(dateFormatter.string(from: item.dateValeur)).frame(minWidth: 100, alignment: .leading)
            Text(dateFormatter.string(from: item.dateValeur)).frame(minWidth: 100, alignment: .leading)
            Text(dateFormatter.string(from: item.dateFin)).frame(minWidth: 100, alignment: .leading)
            Text(String(format: "%.2f", item.amount)).frame(minWidth: 100, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func rowGroup2(_ item: EntitySchedule) -> some View {
        Group {
            Text(String(item.frequence)).frame(minWidth: 100, alignment: .leading)
            Text(item.libelle).frame(minWidth: 120, alignment: .leading)
            Text(String(item.nextOccurrence)).frame(minWidth: 100, alignment: .leading)
            Text(String(item.occurrence)).frame(minWidth: 100, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func rowGroup3(_ item: EntitySchedule) -> some View {
        Group {
            Text(item.paymentMode?.name ?? "N/A").frame(minWidth: 100, alignment: .leading)
            Text(item.category?.rubric?.name ?? "N/A").frame(minWidth: 100, alignment: .leading)
            Text(item.category?.name ?? "").frame(minWidth: 100, alignment: .leading)
            Text(item.account.identity?.name ?? "").frame(minWidth: 120, alignment: .leading)
            Text(item.account.initAccount?.codeAccount ?? "").frame(minWidth: 100, alignment: .leading)
        }
    }
}
