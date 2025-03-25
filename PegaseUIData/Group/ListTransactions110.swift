//
//  ListTransactions110.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData


struct OperationRow: View {
    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
    @EnvironmentObject private var dataManager           : ListDataManager
    @EnvironmentObject private var colorManager          : ColorManager
    
    @State private var selectedTransactions = Set<UUID>()

    @State private var transactions: [EntityTransactions] = [
        EntityTransactions(),
        EntityTransactions()
        // Ajoutez des instances d'exemple de EntityTransactions ici
    ]
    
    @AppStorage("disclosureStates") private var disclosureStatesData: Data = Data()
    @State private var disclosureStates: [String: Bool] = [:]
    
    private func isExpanded(for key: String) -> Binding<Bool> {
        Binding(
            get: { disclosureStates[key, default: false] },
            set: { newValue in
                disclosureStates[key] = newValue
                saveDisclosureState()
            }
        )
    }
    
    var body: some View {
        ForEach(groupTransactionsByYear(transactions: transactions), id: \.year) { yearGroup in
            let yearKey = "year_\(yearGroup.year)" // Clé unique pour chaque année
            
            DisclosureGroup(
                isExpanded: isExpanded(for: yearKey),
                content: {
                    ForEach(yearGroup.monthGroups, id: \.month) { monthGroup in
                        let monthKey = "month_\(yearGroup.year)_\(monthGroup.month)" // Clé unique pour chaque mois
                        
                        DisclosureGroup(
                            isExpanded: isExpanded(for: monthKey),
                            content: {
                                VStack {
                                    List(monthGroup.transactions, selection: $selectedTransactions) { transaction in
                                        TransactionLigne(transaction: transaction)
                                            .foregroundColor(.black)
                                            .frame(minHeight: 30)
                                    }
                                    .frame(minHeight: 800)
                                    Spacer()
                                }
                            },
                            label: { Text("Month: \(monthGroup.month)") }
                        )
                    }
                },
                label: { Text("Year: \(yearGroup.year)") }
            )
        }
        .onAppear(perform: loadDisclosureState)
        .onAppear {
            transactions = dataManager.listTransactions
        }
    }
    
    // Sauvegarde l'état des `DisclosureGroup`
    private func saveDisclosureState() {
        if let data = try? JSONEncoder().encode(disclosureStates) {
            disclosureStatesData = data
        }
    }
    
    // Charge l'état sauvegardé au démarrage
    private func loadDisclosureState() {
        if let loadedData = try? JSONDecoder().decode([String: Bool].self, from: disclosureStatesData) {
            disclosureStates = loadedData
        }
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

struct TransactionLigne: View {
    let transaction: EntityTransactions
    @EnvironmentObject private var colorManager: ColorManager
    
    var body: some View {
        let foregroundColor = colorManager.colorForTransaction(transaction)
        
        HStack {
            Text(transaction.dateOperationString)
                .foregroundColor(.black)
            Spacer()
            Text(transaction.datePointageString)
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.sousOperations.first?.libelle ?? "—")
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.sousOperations.first?.category?.name ?? "—")
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.bankStatementString)
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.checkNumber)
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.statusString)
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.paymentModeString)
                .foregroundColor(foregroundColor)
            Spacer()
            Text(transaction.amountString)
                .foregroundColor(foregroundColor)
        }
    }
}
