//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData


struct ListTransactions: View {

    @Binding var isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: 100, planned: 123.10, engaged: 45.5)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .task {
                    await performTrueTask()
                }
            ContentView10000()
                .frame(minWidth: 200, minHeight: 300)
            Spacer()
        }
    }
    private func performTrueTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
    }
}


struct ContentView10000: View {
    @Environment(\.modelContext) private var context

//    @Query(sort: \EntityTransactions.datePointage, order: .reverse)
    @State private var allTransactions1000: [EntityTransactions] = []

    var body: some View {
        let grouped = groupTransactionsByYear(transactions: allTransactions1000)
        TransactionsListView(data: grouped)
            .navigationTitle("My Transactions")
            .onAppear {
                allTransactions1000 = ListTransactionsManager.shared.getAllDatas()
            }
    }
}

struct GradientText: View {
    var text: String
    var gradientImage: NSImage? {
        NSImage(named: NSImage.Name("Gradient"))
    }
    
    var body: some View {
        Text(text)
            .font(.custom("Silom", size: 16))
            .background(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
    }
}

struct SummaryView: View {
    var executed: Double
    var planned: Double
    var engaged: Double

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("Executed")
                Text(String(format: "%.2f €", executed))
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

            VStack {
                Text("Planned")
                Text(String(format: "%.2f €", planned))
                    .font(.title)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

            VStack {
                Text("Engaged")
                Text(String(format: "%.2f €", engaged))
                    .font(.title)
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: 150)
    }
}

struct YearSectionView: View {
    let yearGroup: TransactionsByYear100
    
    var body: some View {
        Section(header: Text("Année \(yearGroup.year)")
                    .font(.headline)
                    .foregroundColor(.blue)
        ) {
            ForEach(yearGroup.months) { monthGroup in
                MonthDisclosureGroupView(monthGroup: monthGroup, year: yearGroup.year)
            }
        }
    }
}

struct MonthDisclosureGroupView: View {
    let monthGroup: TransactionsByMonth100
    let year: String
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(monthGroup.transactions, id: \.id) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            },
            label: {
                HStack {
                    Text("\(monthGroup.monthName) \(year)")
                    Spacer()
                    Text("Total: \(String(format: "%.2f", monthGroup.totalAmount)) €")
                        .foregroundColor(.primary)
                }
            }
        )
    }
}

struct TransactionsListView: View {
    let data: [TransactionsByYear100]
    
    @State private var selectedTransaction: EntityTransactions?

    var body: some View {
        VStack(spacing: 0) {
            // En-tête des colonnes
            HStack {
                Text("Date of pointing")
                    .frame(width: 90, alignment: .leading)
                Text("Date Transaction")
                    .frame(width: 90, alignment: .leading)
                Text("Comment")
                    .frame(width: 90, alignment: .leading)
                Text("Rubric")
                    .frame(width: 90, alignment: .leading)
                Text("Category")
                    .frame(width: 90, alignment: .leading)
                Text("Mode")
                    .frame(width: 90, alignment: .leading)
                Text("Bank statement")
                    .frame(width: 90, alignment: .leading)
                Text("Check number")
                    .frame(width: 90, alignment: .trailing)
                Text("Statut")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Amount")
                    .frame(width: 90, alignment: .trailing)
            }
            .font(.headline)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            
            Divider()
            
            List(selection: $selectedTransaction) {
                ForEach(data) { yearGroup in
                    YearSectionView(yearGroup: yearGroup)
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 700, minHeight: 400)
        }
    }
}

struct TransactionRowView: View {
    let transaction: EntityTransactions

    // Formatters
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack {
            // Date pointage
            Text(transaction.datePointage != nil
                 ? Self.dateFormatter.string(from: transaction.datePointage!)
                 : "—")
                .frame(width: 90, alignment: .leading)
            
            // Date operation
            Text(transaction.dateOperation != nil
                 ? Self.dateFormatter.string(from: transaction.dateOperation!)
                 : "—")
                .frame(width: 90, alignment: .leading)

            // libelle
            Text(transaction.sousOperations.first?.libelle ?? "—")
                .frame(width: 90, alignment: .leading)

            // Rubric
            Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                .frame(width: 90, alignment: .leading)

            // Categorie
            Text(transaction.sousOperations.first?.category?.name ?? "—")
                .frame(width: 90, alignment: .leading)

            // Mode
            Text(transaction.paymentMode?.name ?? "—")
                .frame(width: 90, alignment: .leading)

            // Bank statement
            Text(String(format: "%.2f", transaction.bankStatement))
                .frame(width: 80, alignment: .trailing)
            
            // Montant
            Text(String(format: "%.2f", transaction.amount))
                .foregroundColor(transaction.amount >= 0 ? .green : .red)
                .frame(width: 80, alignment: .trailing)
            
            // Check number
            Text(transaction.checkNumber)
                .frame(width: 80, alignment: .leading)
            
            // Statut
            Text(statusText)
                .foregroundColor(statusColor)

            // Solde (si vous voulez l’afficher)
            Text(transaction.solde != nil
                 ? String(format: "%.2f", transaction.solde!) : "—")
                .frame(width: 80, alignment: .trailing)

            // Statut
            Text(statusText)
                .foregroundColor(statusColor)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var statusText: String {
        guard let s = transaction.statut else { return "Inconnu" }
        switch s {
        case 0: return "Engaged"
        case 1: return "Executé"
        default: return "Autre"
        }
    }

    private var statusColor: Color {
        guard let s = transaction.statut else { return .gray }
        switch s {
        case 0: return .orange
        case 1: return .green
        default: return .blue
        }
    }
}


/// Représente un regroupement par année.
struct TransactionsByYear100: Identifiable {
    let id = UUID()
    let year: String
    let months: [TransactionsByMonth100]
}

/// Représente un groupe de transactions d'un mois précis (par exemple 2023-02).
struct TransactionsByMonth100: Identifiable {
    let id = UUID()
    let year: String
    let month: Int
    let transactions: [EntityTransactions]

    /// Formatage mois (ex: "Février")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR") // ou "en_US" etc.
        formatter.dateFormat = "LLLL" // nom du mois
        if let transaction = transactions.first,
           let date = transaction.datePointage {
            return formatter.string(from: date).capitalized
        }
        return "Mois Inconnu"
    }

    /// Calcul du total du mois
    var totalAmount: Double {
        transactions.reduce(0.0) { $0 + $1.amount }
    }
}


struct YearMonth: Hashable {
    let year: String
    let month: Int
}

func groupTransactionsByYear(transactions: [EntityTransactions]) -> [TransactionsByYear100] {
    // Dictionnaire [year: [TransactionsByMonth]]
    var dictionaryByYear: [String: [TransactionsByMonth100]] = [:]

    // Dictionnaire [YearMonth : [EntityTransactions]]
    var yearMonthDict: [YearMonth: [EntityTransactions]] = [:]

    for transaction in transactions {
        guard let yearString = transaction.sectionYear else { continue }
        guard let datePointage = transaction.datePointage else { continue }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: datePointage)

        let key = YearMonth(year: yearString, month: month)
        yearMonthDict[key, default: []].append(transaction)
    }

    // Convertir yearMonthDict → dictionaryByYear
    for (yearMonth, trans) in yearMonthDict {
        let byMonth = TransactionsByMonth100(year: yearMonth.year, month: yearMonth.month, transactions: trans)
        dictionaryByYear[yearMonth.year, default: []].append(byMonth)
    }

    // Construire un tableau de TransactionsByYear100
    var result: [TransactionsByYear100] = []
    for (year, monthsArray) in dictionaryByYear {
        // Trier les mois par ordre croissant
        let sortedMonths = monthsArray.sorted { $0.month < $1.month }
        result.append(TransactionsByYear100(year: year, months: sortedMonths))
    }

    // Trier par année décroissante (ou croissante)
    return result.sorted { $0.year > $1.year }
}
