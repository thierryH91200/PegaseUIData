//
//  NotesView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//
import SwiftUI
import SwiftData

struct NotesView: View {
    
    @Binding var isVisible: Bool
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var dataManager = StatementDataManager()

    var body: some View {
        NotesView10()
            .environmentObject(currentAccountManager)
            .environmentObject(dataManager)

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

struct NotesView10: View {
    @Environment(\.modelContext) private var modelContext: ModelContext

    @StateObject private var dataManager = StatementDataManager()
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }

    var body: some View {
        
        Text("NotesView")
            .font(.title)
        Text("\(compteCurrent?.name ?? "Aucun compte courant" )")
            .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                if newAccount != nil {
                    refreshData()
                }
            }
    }
    private func refreshData() {
        BankStatementManager.shared.configure(with: modelContext)
        dataManager.statements = BankStatementManager.shared.getAllDatas()
    }
}
