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

    @State private var selectedStatus: String = "Engaged"
    @State private var selectedRubric: String = "Alimentation"
    @State private var selectedMode: String = "Bank Card"
    @State private var selectedCategory: String = "Alimentation"
    
    let statusOptions = [String(localized :"Engaged"), String(localized :"Pending"), String(localized :"Completed")]
    let rubricOptions = ["Alimentation", "Transport", "Loisirs"]
    @State private var modeOptions = [String]()
    let categoryOptions = ["Alimentation", "Loisirs", "Autres"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Default values ​​for transactions for this account.")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Picker("Statut", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(modeOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Picker("Rubric", selection: $selectedRubric) {
                        ForEach(rubricOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoryOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .frame(width: 600)
            Spacer()

            HStack {
                Spacer()
                Text("Default sign")
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 30, height: 5)
                Spacer()
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            Task {

                if let account = currentAccountManager.currentAccount {
                    PaymentModeManager.shared.configure(with: modelContext)
                    modeOptions = PaymentModeManager.shared.getAllNames(for: account)
                    selectedMode = modeOptions.first!
                } else {
                    print("Aucun compte disponible.")
                }
                
            }
        }

        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

