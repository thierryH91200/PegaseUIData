//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData


struct ListTransactions: View {
    
    @EnvironmentObject var colorManager: ColorManager // ✅ Correct, utilise l'instance globale
    @Binding var isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: 100, planned: 123.10, engaged: 45.5)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .task {
                    await performTrueTask()
                }
//            Text("Couleur sélectionnée : \(colorManager.selectedColorType)")

            ContentView10000()
                .environmentObject(colorManager) // Injecté ici
                .frame(minWidth: 200, minHeight: 300)
            Spacer()
        }
        .onChange(of: colorManager.selectedColorType) { old, new in
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
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent

    @State private var allTransactions1000: [EntityTransactions] = []

    var body: some View {
        let grouped = groupTransactionsByYear(transactions: allTransactions1000)
        TransactionsListView(data: grouped)
            .environmentObject(colorManager) // Passe l'objet aux sous-vues
            .navigationTitle("My Transactions")
            .onAppear {
                allTransactions1000 = ListTransactionsManager.shared.getAllDatas()
            }
            .onChange(of: colorManager.selectedColorType) { old, new in
            }
    }
}

struct YearSectionView: View {
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent

    let yearGroup: TransactionsByYear100
    
    var body: some View {
        Section(header: Text("Year \(yearGroup.year)")
                    .font(.headline)
                    .foregroundColor(.blue)
        ) {
            ForEach(yearGroup.months) { monthGroup in
                MonthDisclosureGroupView(monthGroup: monthGroup, year: yearGroup.year)
                    .environmentObject(colorManager) // Passe l'objet aux sous-vues
            }
        }
    }
}

struct MonthDisclosureGroupView: View {
    let monthGroup: TransactionsByMonth100
    let year: String
    @EnvironmentObject var colorManager: ColorManager
    
    @State private var selectedTransaction: EntityTransactions?

    @AppStorage("disclosureStates") private var disclosureStatesData: Data = Data()
    @State private var disclosureStates: [String: Bool] = [:]

    var groupKey: String {
        "\(monthGroup.monthName)_\(year)" // Clé unique pour chaque groupe
    }

    var isExpanded: Binding<Bool> {
        Binding(
            get: { disclosureStates[groupKey, default: false] },
            set: { newValue in
                disclosureStates[groupKey] = newValue
                saveDisclosureState()
            }
        )
    }

    var body: some View {
        DisclosureGroup(
            isExpanded: isExpanded,
            content: {
                ForEach(monthGroup.transactions, id: \.id) { transaction in
                    TransactionRowView(transaction: transaction, isSelected: transaction == selectedTransaction)
                        .environmentObject(colorManager)
                        .onTapGesture {
                            selectedTransaction = transaction
                        }

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
        .onAppear(perform: loadDisclosureState)
    }

    /// Sauvegarde l'état des `DisclosureGroup`
    private func saveDisclosureState() {
        if let data = try? JSONEncoder().encode(disclosureStates) {
            disclosureStatesData = data
        }
    }

    /// Charge l'état sauvegardé au démarrage
    private func loadDisclosureState() {
        if let loadedData = try? JSONDecoder().decode([String: Bool].self, from: disclosureStatesData) {
            disclosureStates = loadedData
        }
    }
}

struct TransactionsListView: View {
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent

    let data: [TransactionsByYear100]
    
    @State private var selectedTransaction: EntityTransactions?

    var body: some View {
        VStack(spacing: 0) {
            // En-tête des colonnes
            HStack {
                Text("Date of pointing")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Date Transaction")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Comment")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Rubric")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Category")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Mode")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Bank statement")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Check number")
                    .frame(width: 90, alignment: .trailing)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Statut")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
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
                        .environmentObject(colorManager) // Passe l'environnement aux sous-vues

                }
            }
            .listStyle(.inset)
            .frame(minWidth: 700, minHeight: 400)
        }
    }
}

struct TransactionRowView: View {
    let transaction: EntityTransactions?
    let isSelected: Bool

    @EnvironmentObject var colorManager: ColorManager

    // Formatters
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
            HStack {
                
                if let transaction = transaction {
                    
                    // Date pointage
                    Text(transaction.datePointage != nil
                         ? Self.dateFormatter.string(from: transaction.datePointage!)
                         : "—")
                    .frame(width: 90, alignment: .leading)
                    .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Date operation
                    Text(transaction.dateOperation != nil
                         ? Self.dateFormatter.string(from: transaction.dateOperation!)
                         : "—")
                    .frame(width: 90, alignment: .leading)
                    .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // libelle
                    Text(transaction.sousOperations.first?.libelle ?? "—")
                        .frame(width: 90, alignment: .leading)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Rubric
                    Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                        .frame(width: 90, alignment: .leading)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Categorie
                    Text(transaction.sousOperations.first?.category?.name ?? "—")
                        .frame(width: 90, alignment: .leading)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Mode
                    Text(transaction.paymentMode?.name ?? "—")
                        .frame(width: 90, alignment: .leading)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Bank statement
                    Text(String(format: "%.2f", transaction.bankStatement))
                        .frame(width: 80, alignment: .trailing)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Montant
                    Text(String(format: "%.2f", transaction.amount))
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                        .frame(width: 80, alignment: .trailing)
                    //               .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Check number
                    Text(transaction.checkNumber)
                        .frame(width: 80, alignment: .leading)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Statut
                    Text(statusText)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Solde (si vous voulez l’afficher)
                    Text(transaction.solde != nil
                         ? String(format: "%.2f", transaction.solde!) : "—")
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    Spacer()
                }
            }
            .padding(.vertical, 2)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear) // ✅ Met en évidence la ligne sélectionnée
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .onChange(of: colorManager.selectedColorType) { old, new in
                print("couleur changée ",colorManager.selectedColorType)
            }
    }

    private var statusText: String {
        guard let s = transaction?.statut else { return "Inconnu" }
        switch s {
        case 0: return "Engaged"
        case 1: return "Executé"
        case 2: return "Planned"
        default: return "Autre"
        }
    }

    private var statusColor: Color {
        guard let s = transaction?.statut else { return .gray }
        switch s {
        case 0: return .orange
        case 1: return .green
        case 2: return .red
        default: return .blue
        }
    }
}

