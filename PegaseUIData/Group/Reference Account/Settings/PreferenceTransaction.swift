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
       
    @State private var entityPreference  : EntityPreference?
    @State private var entityRubric      : [EntityRubric]      = []
    @State private var entityCategorie   : [EntityCategory]    = []
    @State private var entityPaymentMode : [EntityPaymentMode] = []
    @State private var entityStatus      : [EntityStatus]      = []

    @State var selectedStatus   : EntityStatus?
    @State var selectedRubric   : EntityRubric?
    @State var selectedCategory : EntityCategory?
    @State var selectedMode     : EntityPaymentMode?
    
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
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(entityStatus, id: \.self) { index in
                            Text(index.name).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
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
                    .onChange(of: selectedRubric) { oldRubric, newRubric in
                        if let newRubric = newRubric {
                            // Met à jour la liste des catégories en fonction de la rubrique sélectionnée
                            entityCategorie = newRubric.categorie.sorted { $0.name < $1.name }
                            // Réinitialise la sélection de catégorie si elle ne fait plus partie des catégories disponibles
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
                        ForEach(entityCategorie, id: \.self) {
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
            Task {
                try await configureFormState()
                
                PaymentModeManager.shared.configure(with : modelContext)
                RubricManager.shared.configure(with      : modelContext)
                PreferenceManager.shared.configure(with  : modelContext)
                
                if let account = currentAccountManager.currentAccount {
                    printPreference(for: account)
                    try await refreshData(for : account)
                    printPreference(for: account)

                } else {
                    print("Aucun compte disponible.")
                }
            }
        }
        
        .onDisappear {
            Task {
                await updatePreference(status     : selectedStatus!,
                                 mode       : selectedMode!,
                                 rubric     : selectedRubric!,
                                 category   : selectedCategory!,
                                 preference : entityPreference!)
            }
        }
        
        .onChange(of: currentAccountManager.currentAccount!) {
                oldAccount, newAccount in
                // Mise à jour de la liste en cas de changement de compte
            Task {
                await updatePreference(status     : selectedStatus!,
                                 mode       : selectedMode!,
                                 rubric     : selectedRubric!,
                                 category   : selectedCategory!,
                                 preference : entityPreference!)


                if let account = currentAccountManager.currentAccount {
                    dataManager.preferenceTransaction = nil
                    dataManager.currentAccount = account
                    
                    try await refreshData(for : account)
                }
            }

        }
        
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
    
    func updatePreference(status     : EntityStatus,
                          mode       : EntityPaymentMode,
                          rubric     : EntityRubric,
                          category   : EntityCategory,
                          preference : EntityPreference) async {
        
        Task {
            try await PreferenceManager.shared.update(status     : status,
                                                  mode       : mode,
                                                  rubric     : rubric,
                                                  category   : category,
                                                  preference : preference)
        }

    }
    
    
    func configureFormState() async throws {
        
        // Configuration des modes de paiement
        PaymentModeManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            if let modes = PaymentModeManager.shared.getAllDatas(for: account) {
                // Sélection sécurisée du premier mode de paiement
                selectedMode = entityPreference?.paymentMode
                entityPaymentMode = modes
            }
        }
        // Configuration de status
        StatusManager.shared.configure(with: modelContext)
        if let account = CurrentAccountManager.shared.getAccount() {
            if let status = StatusManager.shared.getAllDatas(for: account) {
                // Sélection sécurisée du premier status
                selectedStatus = entityPreference?.status
                entityStatus = status
            }
        }
    }

    private func refreshData(for account: EntityAccount)  async throws {
        PreferenceManager.shared.configure(with: modelContext)
        dataManager.preferenceTransaction = PreferenceManager.shared.getAllDatas(for: account)
        
        guard let preference = dataManager.preferenceTransaction else { return }

        entityPreference  = preference
        entityStatus      = StatusManager.shared.getAllDatas(for           : account) ?? []
        entityPaymentMode = PaymentModeManager.shared.getAllDatas(for : account) ?? []
        entityRubric      = RubricManager.shared.getAllDatas()
        entityCategorie   = selectedRubric?.categorie ?? []
        
        selectedStatus   = entityPreference?.status
        selectedMode     = entityPreference?.paymentMode
        selectedRubric   = entityPreference?.category?.rubric
        selectedCategory = entityPreference?.category
    }
    
    func printPreference(for account : EntityAccount) {
        print(account.name)
        print("Mode   : ",entityPreference?.paymentMode?.name ?? "")
        print("Status : ",entityPreference?.status?.name ?? "no status")
        print("Rub    : ",entityPreference?.category?.rubric?.name ?? "no rub")
        print("Cat    : ",entityPreference?.category?.name ?? "no cat")
        
        print("Mode   : ", selectedMode?.name ?? "no mode1")
        print("Status : ", selectedStatus?.name ?? "no status1")
        print("Rub    : ", selectedRubric?.name ?? "no rub1")
        print("Cat    : ", selectedCategory?.name ?? "no cat1")

    }
}

