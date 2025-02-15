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
    @Published var preferenceTransacrion: EntityPreference? {
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
    
//    @State private var entityPreference : EntityPreference?
//    @State private var entityRubric : [EntityRubric]?
//    @State private var entityCategorie : [EntityCategory]?
//
//    @State private var selectedStatus: String = "Engaged"
//    @State private var selectedRubric: String
//    @State private var selectedCategory: String
//    @State private var selectedMode: String
//    
//    @State private var statusOptions = [String(localized :"Plannifie"),
//                                        String(localized :"Engaged"),
//                                        String(localized :"Executed")]
//
//    @State private var rubricOptions =  [String]()
//    @State private var categoryOptions =  [String]()
//    @State private var modeOptions = [String]()
//    
    var body: some View {
        Text("Hello")
    }
//        VStack(spacing: 20) {
//            Text("Default values ​​for transactions for this account.")
//                .font(.headline)
//                .padding(.top)
//            
//            HStack(spacing: 30) {
//                VStack(alignment: .leading) {
//                    Picker("Statut", selection: $selectedStatus) {
//                        ForEach(statusOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                    
//                    Picker("Mode", selection: $selectedMode) {
//                        ForEach(modeOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                }
//                
//                VStack(alignment: .leading) {
//                    Picker("Rubric", selection: $selectedRubric) {
//                        ForEach(rubricOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                    
//                    Picker("Category", selection: $selectedCategory) {
//                        ForEach(categoryOptions, id: \.self) {
//                            Text($0)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                }
//            }
//            .frame(width: 600)
//            Spacer()
//
//            HStack {
//                Spacer()
//                Text("Default sign")
//                Rectangle()
//                    .fill(Color.red)
//                    .frame(width: 30, height: 5)
//                Spacer()
//            }
//            .padding(.bottom)
//        }
//        .padding()
//        .onAppear {
//            Task {
//      
//                PaymentModeManager.shared.configure(with: modelContext)
//                RubricManager.shared.configure(with: modelContext)
//                PreferenceManager.shared.configure(with: modelContext)
//
//                if let account = currentAccountManager.currentAccount {
//                    refreshData(for : account)
//                } else {
//                    print("Aucun compte disponible.")
//                }
//            }
//        }
//        
//        .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
//            // Mise à jour de la liste en cas de changement de compte
//            if let account = newAccount {
//                dataManager.preferenceTransacrion = nil
//                dataManager.currentAccount = account
//                refreshData(for: account)
//            }
//        }
//        .cornerRadius(10)
//        .shadow(radius: 5)
//        .padding()
//    }
//    
//    private func refreshData(for account : EntityAccount) {
//        dataManager.preferenceTransacrion = PreferenceManager.shared.getAllDatas(for: account)
//        
//        modeOptions = PaymentModeManager.shared.getAllNames(for: account)
//        var i = modeOptions.firstIndex { $0 == entityPreference?.paymentMode?.name }
//        selectedMode = modeOptions[i!]
//        
//        /// Rubrique
//        self.entityRubric = RubricManager.shared.getAllDatas()
//        rubricOptions = (0..<entityRubric!.count).map { i -> String in
//            return entityRubric![i].name
//        }
//        var j = entityRubric!.firstIndex { $0 == entityPreference?.category?.rubric }
//        selectedRubric = rubricOptions [ j!]
//    }

}

