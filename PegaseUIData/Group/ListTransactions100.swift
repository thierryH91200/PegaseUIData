//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData


struct ListTransactionsView100: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @Binding var isVisible: Bool
    
    var body: some View {
        ListTransactions200(isVisible: $isVisible)
            .environmentObject(currentAccountManager)
        
            .padding()
            .task {
                await performFalseTask()
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
    }
}


struct ListTransactions200: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
    @EnvironmentObject private var dataManager           : ListDataManager
    @EnvironmentObject private var colorManager          : ColorManager
    
    @Binding var isVisible: Bool
    
    @State private var selectedTransactions = Set<UUID>()
    
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: soldeBanque, planned: soldeReel, engaged: soldeFinal)
                .frame(maxWidth: .infinity, maxHeight: 100)
            
            NavigationView {
                
                List {
                    // Titres des colonnes
                    HStack {
                        Text("Date Operation").bold()
                        Spacer()
                        Text("Date Pointage").bold()
                        Spacer()
                        Text("Comment").bold()
                            .frame(width: 150, alignment: .leading)
                        Spacer()
                        Text("Rubric").bold()
                        Spacer()
                        Text("Category").bold()
                        Spacer()
                        Text("Bank Statement").bold()
                        Spacer()
                        Text("Check Number").bold()
                        Spacer()
                        Text("Status").bold()
                        Spacer()
                        Text("Payment Mode").bold()
                        Spacer()
                        Text("Amount").bold()
                    }
                    .padding(.vertical)
                    OperationRow()
                }
            }
        }
        .onChange(of: colorManager.colorChoix) { old, new in
        }
        
        .onAppear() {
            balanceCalculation()
        }
    }
    
    @MainActor
    func loadTransactions() {
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
    }
    
    
    private func balanceCalculation() {
        // Récupère les données de l'init
        InitAccountManager.shared.configure(with: modelContext)
        guard let initCompte = InitAccountManager.shared.getAllDatas() else { return }
        
        // Initialisation des soldes
        var balanceRealise = initCompte.realise
        var balancePrevu   = initCompte.prevu
        var balanceEngage  = initCompte.engage
        let initialBalance = balancePrevu + balanceEngage + balanceRealise
        
        // Vérification des transactions disponibles
        let transactions = dataManager.listTransactions
        
        let count = transactions.count
        
        // Calcul des soldes transaction par transaction
        for index in stride(from: count - 1, to: -1, by: -1) {
            let transaction = transactions[index]
            
            let status = Int(transaction.status?.type ?? 1)
            
            // Mise à jour des soldes en fonction du status
            switch status {
            case 0:
                balancePrevu += transaction.amount
            case 1:
                balanceEngage += transaction.amount
            case 2:
                balanceRealise += transaction.amount
            default:
                balancePrevu += transaction.amount
            }
            
            // Calcul du solde de la transaction
            transaction.solde = (index == count - 1) ?
            (transaction.amount) + initialBalance :
            (transactions[index + 1].solde ?? 0.0) + (transaction.amount)
        }
        
        // Mise à jour des soldes finaux
        self.soldeBanque = balanceRealise
        self.soldeReel   = balanceRealise + balanceEngage
        self.soldeFinal  = balanceRealise + balanceEngage + balancePrevu
        
        //    NotificationCenter.send(.updateBalance) // Décommente si nécessaire
    }

    private func groupTransactionsByYear(transactions: [EntityTransactions]) -> [YearGroup] {
        var groupedItems: [YearGroup] = []
        let calendar = Calendar.current
        
        // Group transactions by year
        let groupedByYear = Dictionary(grouping: transactions) { (transaction) -> Int in
            let components = calendar.dateComponents([.year], from: transaction.datePointage ?? Date())
            return components.year ?? 0
        }
        
        for (year, yearTransactions) in groupedByYear {
            var yearGroup = YearGroup(year: "\(year)", monthGroups: [])
            
            let groupedByMonth = Dictionary(grouping: yearTransactions) { (transaction) -> Int in
                let components = calendar.dateComponents([.month], from: transaction.datePointage ?? Date())
                return components.month ?? 0
            }
            
            for (month, monthTransactions) in groupedByMonth {
                let monthName = DateFormatter().monthSymbols[month - 1]
                let monthGroup = MonthGroup(month: monthName, transactions: monthTransactions)
                
                yearGroup.monthGroups.append(monthGroup)
            }
            
            groupedItems.append(yearGroup)
        }
        
        return groupedItems
    }
}

struct YearGroup {
    var year: String
    var monthGroups: [MonthGroup]
}

struct MonthGroup {
    var month: String
    var transactions: [EntityTransactions]
}

extension EntityTransactions {
    var dateOperationString: String {
        let date = dateOperation?.formatted() ?? "N/A"
        
        return dateOperation?.formatted() ?? "N/A"
    }
    
    var datePointageString: String {
        datePointage?.formatted() ?? "N/A"
    }
    
    var bankStatementString: String {
        String(format: "%.2f", bankStatement)
    }
    
    var statusString: String {
        status.map { "\($0)" } ?? "N/A"
    }
    
    var paymentModeString: String {
        paymentMode.map { "\($0)" } ?? "N/A"
    }
    
    var amountString: String {
        String(format: "%.2f", amount)
    }
}

// Exemple d'extension pour formater les dates
extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}

