//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 23/05/2025.
//

import AppKit
import SwiftUI
import UserNotifications

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
    @State private var frequency: String = ""
    
    @State private var entityPaymentMode : [EntityPaymentMode] = []
    @State private var entityRubric      : [EntityRubric]      = []
    @State private var entityCategorie   : [EntityCategory]    = []
    @State private var frequenceType     : [String]    = []
    
    @State var selectedRubric   : EntityRubric?
    @State var selectedCategory : EntityCategory?
    @State var selectedTypeIndex = 0
    @State var selectedMode     : EntityPaymentMode?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            Group {
                HStack {
                    Text("Start Date").frame(width: 100, alignment: .leading)
                    DatePicker("", selection: $dateDebut, displayedComponents: .date)
                }
                
                HStack {
                    Text("Value Date").frame(width: 100, alignment: .leading)
                    DatePicker("", selection: $dateValeur, displayedComponents: .date)
                }
                
                HStack {
                    Text("Occurence").frame(width: 100, alignment: .leading)
                    TextField("Occurence", text: $occurence)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Frequency").frame(width: 100, alignment: .leading)
                    TextField("", text: $frequency)
                        .textFieldStyle(.roundedBorder)
                    Picker("", selection: $selectedTypeIndex) {
                        ForEach(0..<frequenceType.count, id: \.self) { index in
                            Text(frequenceType[index]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("End Date").frame(width: 100, alignment: .leading)
                    DatePicker("", selection: $dateFin, displayedComponents: .date)
                }
                
                HStack {
                    Text("Next occurence").frame(width: 100, alignment: .leading)
                    TextField("Next occurence", text: $nextOccurence)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Comment").frame(width: 100, alignment: .leading)
                    TextField("Comment", text: $libelle)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("Mode").frame(width: 100, alignment: .leading)
                    Picker("", selection: $selectedMode) {
                        ForEach(entityPaymentMode, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                
                HStack {
                    Text("Rubric")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $selectedRubric) {
                        ForEach(entityRubric, id: \.self) {
                            Text($0.name).tag($0 as EntityRubric?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .onChange(of: selectedRubric) { _, newRubric in
                    if let newRubric = newRubric {
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
                
                HStack {
                    Text("Category")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $selectedCategory) {
                        ForEach(entityCategorie, id: \.self) {
                            Text($0.name).tag($0 as EntityCategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("Amount")
                        .frame(width: 100, alignment: .leading)
                    TextField("Amount", text: $amount)
                        .textFieldStyle(.roundedBorder)
                }
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
            
            guard let account = CurrentAccountManager.shared.getAccount() else {
                print("Erreur : aucun compte courant trouvé.")
                return
            }
            frequenceType = [
                String(localized :"Day",table : "Account"),
                String(localized :"Week",table : "Account"),
                String(localized :"Month",table : "Account"),
                String(localized :"Year",table : "Account")]
            
            
            PreferenceManager.shared.configure(with: modelContext)
            let entityPreference = PreferenceManager.shared.getAllDatas(for: account)
            PaymentModeManager.shared.configure(with: modelContext)
            RubricManager.shared.configure(with: modelContext)
            entityPaymentMode = PaymentModeManager.shared.getAllDatas()!
            entityRubric = RubricManager.shared.getAllDatas()
            
            if let scheduler = scheduler {
                //                scheduler.account = currentAccount
                amount = String(scheduler.amount)
                dateValeur = scheduler.dateValeur
                dateDebut = scheduler.dateDebut
                dateFin = scheduler.dateFin
                frequence = String(scheduler.frequence)
                libelle = scheduler.libelle
                nextOccurence = String(scheduler.nextOccurence)
                occurence = String(scheduler.occurence)
                frequency = String(scheduler.frequence)
                
                selectedMode = scheduler.paymentMode
                selectedCategory = scheduler.category
                selectedRubric = scheduler.category?.rubric
                selectedTypeIndex = Int(scheduler.typeFrequence)
                
            } else {
                //                account = scheduler.account!
                amount = String(scheduler?.amount ?? 0.0)
                dateValeur = Date().noon
                dateDebut = Date().noon
                dateFin = Date().noon
                frequence = "2"
                libelle = ""
                nextOccurence = "1"
                occurence = "12"
                frequency = "1"
                
                selectedMode = entityPreference?.paymentMode
                selectedRubric = entityPreference?.category?.rubric
                selectedCategory = entityPreference!.category
                selectedTypeIndex = 2
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
           let frequencyType = Int16(exactly: selectedTypeIndex),
           let amount = Double(amount) {
            
            newItem.amount = amount
            newItem.dateValeur = dateValeur.noon
            newItem.dateDebut = dateDebut.noon
            newItem.dateFin = dateFin.noon
            newItem.frequence = frequence
            newItem.libelle = libelle
            newItem.nextOccurence = nextOccurence
            newItem.occurence = occurence
            newItem.typeFrequence = Int16(frequencyType)
            
            newItem.paymentMode = selectedMode
            newItem.category = selectedCategory
            
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
