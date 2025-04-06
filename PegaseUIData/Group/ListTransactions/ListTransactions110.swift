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
    
    @Binding var selectedTransactions: Set<UUID>
    
    private var transactions: [EntityTransactions] { dataManager.listTransactions }
    
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
        
        Spacer()
        Divider()
        VStack {
            Text("Sélections : \(selectedTransactions.count) transaction(s)")
                .padding()
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.windowBackgroundColor))
        .frame(maxHeight: .infinity, alignment: .bottom) // Permet d'étendre la liste sur toute la hauteur disponible
        .frame(maxHeight: .infinity) // Assure l'extension verticale de la vue
    }
    
//    private func afficherDetails(_ transaction: EntityTransactions) {
//        print("Afficher les détails de la transaction : \(transaction)")
//
//        if let index = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
//            TransactionDetailView(currentSectionIndex: index, selectedTransaction: $selectedTransactions)
//        } else {
//            print("Erreur : transaction non trouvée dans la liste.")
//        }
//    }
    
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
            let components = calendar.dateComponents([.year], from: transaction.datePointage)
            return components.year ?? 0
        }
        
        for (year, yearTransactions) in groupedByYear {
            var yearGroup = YearGroup(year: "\(year)", monthGroups: [])
            
            let groupedByMonth = Dictionary(grouping: yearTransactions) { (transaction) -> Int in
                let components = calendar.dateComponents([.month], from: transaction.datePointage)
                return components.month ?? 0
            }
            
            for (month, monthTransactions) in groupedByMonth.sorted(by: { $0.key > $1.key }) {
                let monthName = DateFormatter().monthSymbols[month - 1]
                let monthGroup = MonthGroup(month: monthName,
                                            transactions: monthTransactions.sorted(by: { $0.dateOperation > $1.dateOperation }))
                
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
            Text(transaction.sousOperations.first?.amountString ?? "—").frame(width: 150, alignment: .leading)

            Text(transaction.bankStatementString).frame(width: 120, alignment: .leading)
            Text(transaction.checkNumber).frame(width: 120, alignment: .leading)
            Text(transaction.statusString).frame(width: 100, alignment: .leading)
            Text(transaction.paymentModeString).frame(width: 120, alignment: .leading)
            Text(transaction.amountString).frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 6) // Ajout d'un peu d'espace
        .background(backgroundColor)
        .foregroundColor( textColor )
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
                supprimerTransactionsSelectionnees()
            }) {
                Label("Remove", systemImage: "trash")
            }
            .disabled(selectedTransactions.isEmpty) // Désactive le bouton si rien n'est sélectionné
            .padding()
        }
//        .sheet(isPresented: $showTransactionInfo) {
//            if let index = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
//                TransactionDetailView(currentSectionIndex: index, selectedTransaction: $selectedTransactions)
//                    .frame(minWidth: 400, minHeight: 300)
//            } else {
//                Text("Erreur : transaction non trouvée dans la liste.")
//                    .foregroundColor(.red)
//                    .padding()
//            }
//        }
        .popover(isPresented: $showTransactionInfo, arrowEdge: .top) {
            if let index = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
                TransactionDetailView(currentSectionIndex: index, selectedTransaction: $selectedTransactions)
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                Text("Erreur : transaction non trouvée dans la liste.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    

    private func transaction(for id: UUID) -> EntityTransactions? {
        _ = selectedTransactions.compactMap { id in
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
        print("Transaction sélectionnée : \(transactionManager.selectedTransaction?.id.uuidString ?? "Aucune")")

        transactionManager.isCreationMode = false
    }
    
    private func supprimerTransactionsSelectionnees() {
        withAnimation {
            let transactionsToDelete = dataManager.listTransactions.filter { selectedTransactions.contains($0.id) }

            for transaction in transactionsToDelete {
                if !transaction.isDeleted {
                    modelContext.delete(transaction)
                }
            }

            // Met à jour la liste des transactions après suppression
            dataManager.listTransactions.removeAll { selectedTransactions.contains($0.id) }
            selectedTransactions.removeAll()
        }
    }
}


