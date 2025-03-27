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
    
//    @State var showTransactionInfo : Bool = false


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
                                        TransactionLigne(transaction: transaction, selectedTransactions: $selectedTransactions)
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
    
    private func afficherDetails(_ transaction: EntityTransactions) {
        // Implémente l'affichage des détails, ex: ouvrir une nouvelle vue
        print("Afficher les détails de la transaction : \(transaction)")
//        TransactionDetailView(transaction: transaction)
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
            
            for (month, monthTransactions) in groupedByMonth.sorted(by: { $0.key > $1.key }) {
                let monthName = DateFormatter().monthSymbols[month - 1]
                let monthGroup = MonthGroup(month: monthName,
                                            transactions: monthTransactions.sorted(by: { $0.dateOperation! > $1.dateOperation! }))
                
                yearGroup.monthGroups.append(monthGroup)
            }
            
            groupedItems.append(yearGroup)
        }
        return groupedItems
    }
    
}

struct TransactionLigne: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataManager      : ListDataManager
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    @EnvironmentObject private var colorManager: ColorManager

    let transaction: EntityTransactions
    @Binding var selectedTransactions: Set<UUID>
    
    @State var showTransactionInfo: Bool = false
    @GestureState private var isShiftPressed = false
    @GestureState private var isCmdPressed = false

    var isSelected: Bool {
        selectedTransactions.contains(transaction.id)
    }

    var body: some View {
        let isSelected = selectedTransactions.contains(transaction.id)
        var backgroundColor = isSelected ? Color.blue.opacity(0.5) : Color.clear
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(transaction)

        HStack {
            Text(transaction.dateOperationString).frame(width: 120, alignment: .leading)
            Text(transaction.datePointageString).frame(width: 120, alignment: .leading)
            Text(transaction.sousOperations.first?.libelle ?? "—").frame(width: 150, alignment: .leading)
            Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—").frame(width: 100, alignment: .leading)
            Text(transaction.sousOperations.first?.category?.name ?? "—").frame(width: 100, alignment: .leading)
            Text(transaction.bankStatementString).frame(width: 120, alignment: .leading)
            Text(transaction.checkNumber).frame(width: 120, alignment: .leading)
            Text(transaction.statusString).frame(width: 100, alignment: .leading)
            Text(transaction.paymentModeString).frame(width: 120, alignment: .leading)
            Text(transaction.amountString).frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 6) // Ajout d'un peu d'espace
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(8) // Arrondi les coins du fond sélectionné
        .contentShape(Rectangle()) // Permet de cliquer sur toute la ligne
        .onTapGesture {
            toggleSelection()
        }
        .onHover { hovering in
            if !isSelected {
                withAnimation {
                    backgroundColor = hovering ? Color.gray.opacity(0.1) : Color.clear
                }
            }
        }

        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isCmdPressed) { _, state, _ in state = NSEvent.modifierFlags.contains(.command) }
                .updating($isShiftPressed) { _, state, _ in state = NSEvent.modifierFlags.contains(.shift) }
        )
        .contextMenu {
            Button(action: {
                transactionManager.selectedTransaction = transaction
                transactionManager.isCreationMode = false
                showTransactionInfo = true
            }) {
                Label("Show details", systemImage: "info.circle")
            }
            
            Button(role: .destructive, action: {
                supprimerTransaction(transaction)
            }) {
                Label("Remove", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showTransactionInfo) {
            TransactionDetailView(transaction: transaction)
                .frame(minWidth: 400, minHeight: 300)
        }
    }
    
    private func transaction(for id: UUID) -> EntityTransactions? {
        let selectedTransactionsList = selectedTransactions.compactMap { id in
            transaction(for: id)
        }
        return dataManager.listTransactions.first { $0.id == id }
    }
    
    private func toggleSelection() {
        if NSEvent.modifierFlags.contains(.command) || NSEvent.modifierFlags.contains(.shift) {
            // Mode sélection multiple : ajoute ou enlève de la sélection
            if selectedTransactions.contains(transaction.id) {
                selectedTransactions.remove(transaction.id)
            } else {
                selectedTransactions.insert(transaction.id)
            }
        } else {
            // Mode sélection unique : efface la sélection précédente
            selectedTransactions.removeAll()
            selectedTransactions.insert(transaction.id)
        }

        // Met à jour la transaction sélectionnée dans le manager
        if let firstSelectedId = selectedTransactions.first {
            transactionManager.selectedTransaction = dataManager.listTransactions.first { $0.id == firstSelectedId }
        }
        transactionManager.isCreationMode = false
    }
    
    private func supprimerTransaction(_ transaction: EntityTransactions) {
        withAnimation {
            ListTransactionsManager.shared.configure(with: modelContext)
            ListTransactionsManager.shared.remove(entity: transaction)
            dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas()
        }
    }
}
