
import SwiftUI
import SwiftData


struct ContentView10: View {
    @State private var transactions: [EntityTransactions] = [
        EntityTransactions(), // Ajoutez des instances d'exemple de EntityTransactions ici
    ]
    
    var body: some View {
        NavigationView {
            List {
                // Titres des colonnes
                HStack {
                    Text("Date Operation").bold()
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
                
                // Données des transactions organisées par années et mois
                ForEach(groupTransactionsByYear(transactions: transactions), id: \.year) { yearGroup in
                    DisclosureGroup("Year: \(yearGroup.year)") {
                        ForEach(yearGroup.monthGroups, id: \.month) { monthGroup in
                            DisclosureGroup("Month: \(monthGroup.month)") {
                                ForEach(monthGroup.transactions, id: \.id) { transaction in
                                    HStack {
                                        Text(transaction.dateOperationString)
                                        Spacer()
                                        Text(transaction.bankStatementString)
                                        Spacer()
                                        Text(transaction.checkNumber)
                                        Spacer()
                                        Text(transaction.statusString)
                                        Spacer()
                                        Text(transaction.paymentModeString)
                                        Spacer()
                                        Text(transaction.amountString)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .frame(minWidth: 800, minHeight: 600)
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
                var monthGroup = MonthGroup(month: monthName, transactions: monthTransactions)
                
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

private extension EntityTransactions {
    var dateOperationString: String {
        dateOperation?.formatted() ?? "N/A"
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

