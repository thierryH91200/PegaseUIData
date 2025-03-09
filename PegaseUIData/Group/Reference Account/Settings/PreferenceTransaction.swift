//
//  File.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

final class PreferenceDataManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var preferenceTransaction: EntityPreference? {
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

struct PreferenceTransactionView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager : CurrentAccountManager
    @EnvironmentObject var dataManager : PreferenceDataManager
    
    @State private var entityPreference : EntityPreference?
    @State private var entityRubric : [EntityRubric] = []
    @State private var entityCategorie : [EntityCategory]  = []
    @State private var entityPaymentMode : [EntityPaymentMode] = []

    @Binding var selectedStatus: Int
    @Binding var selectedRubric: EntityRubric?
    @Binding var selectedCategory: EntityCategory?
    @Binding var selectedMode: EntityPaymentMode?
    
    @State private var statusOptions = [String(localized :"Plannifie"),
                                        String(localized :"Engaged"),
                                        String(localized :"Executed")]

    @State private var rubricOptions =  [String]()
    @State private var categoryOptions =  [String]()
    @State private var modeOptions = [String]()
    
    var body: some View {

        VStack(spacing: 20) {
            Text("Default values ​​for transactions for this account.")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    FormField(label: String(localized: "Status")) {
                        Picker("", selection: $selectedStatus) {
                            ForEach(statusOptions.indices, id: \.self) { index in
                                Text(statusOptions[index]).tag(index)
                            }
                        }
                    }
                    
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(entityPaymentMode, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Picker("Rubric", selection: $selectedRubric) {
                        ForEach(entityRubric, id: \.self) {
                            Text($0.name).tag($0 as EntityRubric?)                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(selectedRubric!.categorie, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .frame(width: 600)

            HStack {
                Text("Default sign")
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 5)
            }
            .padding(.bottom)
            Spacer()

        }
        .padding()
        .onAppear {
            
            PaymentModeManager.shared.configure(with: modelContext)
            RubricManager.shared.configure(with: modelContext)
            PreferenceManager.shared.configure(with: modelContext)
            
            if let account = currentAccountManager.currentAccount {
                refreshData(for : account)
            } else {
                print("Aucun compte disponible.")
            }
            
            if statusOptions.indices.contains(1) {
                selectedStatus = 1
            }
        }
        
        .onChange(of: currentAccountManager.currentAccount) { oldAccount, newAccount in
            // Mise à jour de la liste en cas de changement de compte
            if let account = newAccount {
                dataManager.preferenceTransaction = nil
                dataManager.currentAccount = account
                refreshData(for: account)
            }
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    private func refreshData(for account : EntityAccount) {
        
        PreferenceManager.shared.configure(with: modelContext)
        dataManager.preferenceTransaction = PreferenceManager.shared.getAllDatas(for: account)
        entityPreference = dataManager.preferenceTransaction
        
        // Status
        selectedStatus = Int(entityPreference?.status ?? 1)
        
        // Mode
        self.entityPaymentMode = PaymentModeManager.shared.getAllDatas(for: account)!
        let i = entityPaymentMode.firstIndex { $0 == entityPreference?.paymentMode}
        selectedMode = entityPaymentMode[i ?? 0]
        
        // Rubrique
        self.entityRubric = RubricManager.shared.getAllDatas()
        let j = entityRubric.firstIndex { $0 == entityPreference?.category?.rubric }
        selectedRubric = entityRubric [ j ?? 0]
        
        // Categorie
        entityCategorie = selectedRubric!.categorie
        let k = entityCategorie.firstIndex { $0 == entityPreference?.category! }
        selectedCategory = entityCategorie [ k ?? 0]

        printPreference(for: account)
    }
    
    func printPreference(for account : EntityAccount) {
        print(account.name)
        print(entityPreference?.paymentMode?.name ?? "")
        print(entityPreference?.status ?? -1)
        print(entityPreference?.category?.name ?? "no cat")
        print(entityPreference?.category?.rubric?.name ?? "no rub")
    }
}

