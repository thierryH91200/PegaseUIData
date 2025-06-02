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
        VStack(spacing: 2) {
            if let account = CurrentAccountManager.shared.currentAccount {
                Text("Account: \(account.name)")
                    .font(.headline)
                    .padding(.bottom, 0)
            }
            SchedulerTable(schedulers: dataManager.schedulers, selection: $selectedItem)
                .frame(height: 300)
                .padding(.top, 0)
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
                    selected = nil
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
            dataManager.schedulers = SchedulerManager.shared.getAllData()!
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
        dataManager.schedulers = SchedulerManager.shared.getAllData()!
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
        .background(Color.white)
        .frame(minHeight: 300)
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
