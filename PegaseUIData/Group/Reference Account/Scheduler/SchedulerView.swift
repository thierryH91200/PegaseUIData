//
//  SchedulerView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import SwiftData
import UserNotifications


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
        Scheduler()
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
            SchedulerFormView(isPresented: $isAddDialogPresented, isModeCreate: $modeCreate, scheduler: $selected)
        }
        
        .sheet(isPresented: $isEditDialogPresented) {
            SchedulerFormView(isPresented: $isEditDialogPresented, isModeCreate: $modeCreate, scheduler: $selectedSchedule)
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

// Vue pour la boîte de dialogue d'ajout
struct SchedulerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var schedulerDataManager: SchedulerDataManager
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    
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
    
    @State private var entityPaymentMode : [EntityPaymentMode] = []
    @State private var entityRubric      : [EntityRubric]      = []
    @State private var entityCategorie   : [EntityCategory]    = []


    @State var selectedRubric   : EntityRubric?
    @State var selectedCategory : EntityCategory?
    @State var selectedMode     : EntityPaymentMode?

    var body: some View {
        VStack(spacing: 20) {
            Text(isModeCreate ? "Add scheduler" : "Edit scheduler")
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
                TextField("Next occurence", text: $nextOccurence)
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
            
            HStack(spacing: 30) {
                Picker("Mode", selection: $selectedMode) {
                    ForEach(entityPaymentMode, id: \..self) {
                        Text($0.name).tag($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            
            VStack(alignment: .leading) {
                Picker("Rubric", selection: $selectedRubric) {
                    ForEach(entityRubric, id: \..self) {
                        Text($0.name).tag($0 as EntityRubric?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedRubric) { _, newRubric in
                    if let newRubric = newRubric {
                        // Mise à jour des catégories en fonction de la rubrique sélectionnée
                        entityCategorie = newRubric.categorie.sorted { $0.name < $1.name }
                        if let selected = selectedCategory,
                           !entityCategorie.contains(where: { $0 == selected }) {
                            selectedCategory = entityCategorie.first
                        }
                    } else {
                        entityCategorie = []
                        selectedCategory = nil
                    }
                }
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(entityCategorie, id: \..self) {
                        Text($0.name).tag($0 as EntityCategory?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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
            PaymentModeManager.shared.configure(with: modelContext)
            RubricManager.shared.configure(with: modelContext)
            entityPaymentMode = PaymentModeManager.shared.getAllDatas()!
            entityRubric = RubricManager.shared.getAllDatas()



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
            let allSchedulers = SchedulerManager.shared.getAllDatas()!
            schedulerDataManager.schedulers = allSchedulers
            if let last = allSchedulers.sorted(by: { $0.dateValeur < $1.dateValeur }).last {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    schedulerDataManager.selectScheduler(last)
                }
            }
            NotificationManager.shared.scheduleReminder(for: newItem)
        }
    }
}

extension Notification.Name {
    static let didSelectScheduler = Notification.Name("didSelectScheduler")
}

// MARK: - NotificationManager
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    func scheduleReminder(for scheduler: EntitySchedule) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Schedule"
        content.body = "Reminder: \(scheduler.libelle) is due soon."
        content.sound = .default
        
        let triggerDate = scheduler.dateValeur.addingTimeInterval(-86400) // 1 day before
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: scheduler.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminder(for scheduler: EntitySchedule) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [scheduler.id.uuidString])
    }
}


struct UpcomingRemindersView: View {
    
    @Environment(\.modelContext) private var modelContext

    let upcoming: [EntitySchedule]
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("🔔 Upcoming Reminders")
                .font(.headline)
            
            let filteredUpcoming = upcoming.filter { $0.dateValeur >= Calendar.current.startOfDay(for: Date()) }
            
            if filteredUpcoming.isEmpty {
                Text("No scheduled operations.")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(filteredUpcoming) { item in
                        HStack {
                            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: item.dateValeur).day ?? 0
                            let iconName = daysRemaining <= 1 ? "exclamationmark.triangle.fill" : "calendar"
                            let iconColor: Color = daysRemaining <= 1 ? .red : (daysRemaining <= 7 ? .orange : .green)
                            
                            Image(systemName: iconName)
                                .foregroundColor(iconColor)
                            
                            VStack(alignment: .leading) {
                                Text(item.libelle)
                                    .fontWeight(.medium)
                                Text("Date : \(dateFormatter.string(from: item.dateValeur))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.2f", item.amount))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onAppear {
                    RubricManager.shared.configure(with: modelContext)
                    CategoriesManager.shared.configure(with: modelContext)
                    for entitySchedule in upcoming {
                        SchedulerManager.shared.createTransaction(entitySchedule: entitySchedule)
                    }
                }

            }
        }
        .padding()
    }
}
