//
//  SettingView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI

struct SettingView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        SettingTab()
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
enum TabSelection: Hashable {
    case rubric
    case modePaiement
    case preference
}
struct SettingTab: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    
    @StateObject private var chequeViewManager       = CheckDataManager()
    @StateObject private var modePaiementDataManager = ModePaiementDataManager()
    @StateObject private var rubricDataManager       = RubricDataManager()
    @StateObject private var preferenceDataManager   = PreferenceDataManager()
    
    @State private var selectedTab: TabSelection = .rubric
    var body: some View {
        
        TabView {
            
//            Tab ("Rubric", systemImage: "house", value: .rubric ) {
//                RubricView()
//                    .environmentObject(currentAccountManager)
//                    .environmentObject(rubricDataManager)
//                
//            }
//        }
            RubricView()
                .environmentObject(currentAccountManager)
                .environmentObject(rubricDataManager)
                .tabItem {
                    Label ("Rubric", systemImage: "house" )
                }

            ModePaymentView()
                .environmentObject(currentAccountManager)
                .environmentObject(modePaiementDataManager)

                .tabItem {
                    Label("Payment method", systemImage: "eurosign.bank.building")
                }
            
            PreferenceTransactionView()
                .environmentObject(currentAccountManager)
                .environmentObject(preferenceDataManager)
            
                .tabItem {
                    Label("Transaction", systemImage: "person")
                }
            
            CheckView()
                .environmentObject(currentAccountManager)
                .environmentObject(chequeViewManager)

                .tabItem {
                    Label("Check", systemImage: "person")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
    }
}
