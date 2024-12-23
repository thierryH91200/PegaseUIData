//
//  exemple2.swift
//  test2
//
//  Created by Thierry hentic on 26/10/2024.
//


import SwiftUI

struct Identy: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        Accueil()
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


struct Accueil: View {
    var body: some View {
        TabView {
            Account()
                .tabItem {
                    Label("Account", systemImage: "house")
                }
            
            Bank()
                .tabItem {
                    Label("Bank", systemImage: "eurosign.bank.building")
                }
            
            Identite()
                .tabItem {
                    Label("Identities", systemImage: "person")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
    }
}

struct Account: View {
    var body: some View {
        VStack {
            AccountView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}

struct Bank: View {
    var body: some View {
        VStack {
            BankView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}

struct Identite: View {
    var body: some View {
        VStack {
            IdentyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1) // Priorité élevée pour occuper tout l’espace disponible
        }
        .padding()
    }
}



