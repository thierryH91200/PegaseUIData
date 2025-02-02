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

struct SettingTab: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var chequeViewManager = CheckViewManager()
    @StateObject private var modePaiementViewManager = ModePaiementViewManager()

    
    var body: some View {
        TabView {
            RubricView()
                .tabItem {
                    Label("Rubric", systemImage: "house")
                }
            
            ModePaymentView()
                .environmentObject(currentAccountManager)
                .environmentObject(modePaiementViewManager)

                .tabItem {
                    Label("Payment mode", systemImage: "eurosign.bank.building")
                }
            
            TransactionView()
                .tabItem {
                    Label("Transaction", systemImage: "person")
                }
            ChequeVIew1()
                .tabItem {
                    Label("Check", systemImage: "person")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
    }
}


struct ChequeVIew1: View {
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var chequeViewManager = CheckViewManager()

    var body: some View {
        VStack {
            CheckView()
                .environmentObject(currentAccountManager)
                .environmentObject(chequeViewManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}


