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
    @State private var info: String = ""
    
    private var transactions: [EntityTransactions] { dataManager.listTransactions }
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    @State var name : String = "NID"
//    @AppStorage("disclosureStates" + name) var disclosureStatesData: Data = Data()

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
        VStack(spacing: 0) {
            ScrollView {
                ForEach(groupTransactionsByYear(transactions: transactions), id: \.year) { yearGroup in
                    let yearKey = "year_\(yearGroup.year)"
                    DisclosureGroup(
                        isExpanded: isExpanded(for: yearKey),
                        content: {
                            ForEach(yearGroup.monthGroups, id: \.month) { monthGroup in
                                let monthKey = "month_\(yearGroup.year)_\(monthGroup.month)"
                                DisclosureGroup(
                                    isExpanded: isExpanded(for: monthKey),
                                    content: {
                                        VStack {
                                            List(monthGroup.transactions,
                                                 selection: $selectedTransactions) { transaction in
                                                TransactionLigne(transaction: transaction,
                                                                 selectedTransactions: $selectedTransactions)
                                                    .foregroundColor(.black)
                                                    .frame(minHeight: 30)
                                            }
                                            .frame(minHeight: 800)
                                        }
                                    },
                                    label: {
                                        Label("Month: \(monthGroup.month)", systemImage: "calendar")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.primary)
                                    }
                                )
                            }
                        },
                        label: {
                            Label("Year: \(yearGroup.year)", systemImage: "clock.arrow.circlepath")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                    )
                }
            }
            .onAppear(perform: loadDisclosureState)
            .onAppear {
                name = compteCurrent?.name ?? "NID"
                let key = "disclosureStates" + name
                if let savedData = UserDefaults.standard.data(forKey: key),
                   let loadedStates = try? JSONDecoder().decode([String: Bool].self, from: savedData) {
                    disclosureStates = loadedStates
                }
            }
        }
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
        let key = "disclosureStates" + name
        if let data = try? JSONEncoder().encode(disclosureStates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    // Charge l'état sauvegardé au démarrage
    private func loadDisclosureState() {
        let key = "disclosureStates" + name
        if let savedData = UserDefaults.standard.data(forKey: key),
           let loadedStates = try? JSONDecoder().decode([String: Bool].self, from: savedData) {
            disclosureStates = loadedStates        }
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

enum ColumnWidths {
    static let dateOperation: CGFloat = 120
    static let datePointage: CGFloat = 120
    static let libelle: CGFloat = 150
    static let rubrique: CGFloat = 100
    static let categorie: CGFloat = 100
    static let sousMontant: CGFloat = 100
    static let releve: CGFloat = 120
    static let cheque: CGFloat = 120
    static let statut: CGFloat = 100
    static let modePaiement: CGFloat = 120
    static let montant: CGFloat = 100
}

struct TransactionLigne: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataManager  : ListDataManager
    @EnvironmentObject var transactionManager   : TransactionSelectionManager
    @EnvironmentObject private var colorManager : ColorManager

    let transaction: EntityTransactions
    @Binding var selectedTransactions: Set<UUID>
    
    @State var showTransactionInfo: Bool = false
    @GestureState private var isShiftPressed = false
    @GestureState private var isCmdPressed = false
    
    @State private var backgroundColor = Color.clear

    var isSelected: Bool {
        selectedTransactions.contains(transaction.id)
    }

    var body: some View {
        let isSelected = selectedTransactions.contains(transaction.id)
        var backgroundColor = isSelected ? Color.blue.opacity(0.5) : Color.clear
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(transaction)

        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                Group {
                    Text(transaction.dateOperationString).frame(width: ColumnWidths.dateOperation, alignment: .leading)
                    verticalDivider()
                    Text(transaction.datePointageString).frame(width: ColumnWidths.datePointage, alignment: .leading)
                    verticalDivider()
                    Text(transaction.sousOperations.first?.libelle ?? "—").frame(width: ColumnWidths.libelle, alignment: .leading)
                    verticalDivider()
                    Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—").frame(width: ColumnWidths.rubrique, alignment: .leading)
                    verticalDivider()
                    Text(transaction.sousOperations.first?.category?.name ?? "—").frame(width: ColumnWidths.categorie, alignment: .leading)
                    verticalDivider()
                    Text(transaction.sousOperations.first?.amountString ?? "—").frame(width: ColumnWidths.sousMontant, alignment: .leading)
                    verticalDivider()
                    Text(transaction.bankStatementString).frame(width: ColumnWidths.releve, alignment: .leading)
                    verticalDivider()
                    Text(transaction.checkNumber).frame(width: ColumnWidths.cheque, alignment: .leading)
                    verticalDivider()
                }
                Group {
                    Text(transaction.statusString).frame(width: ColumnWidths.statut, alignment: .leading)
                    verticalDivider()
                    Text(transaction.paymentModeString).frame(width: ColumnWidths.modePaiement, alignment: .leading)
                    verticalDivider()
                    Text(transaction.amountString).frame(width: ColumnWidths.montant, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(EdgeInsets()) // ⬅️ Supprime la marge à gauche des lignes
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
                .updating($isCmdPressed)   { _, state, _ in state = NSEvent.modifierFlags.contains(.command) }
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
            Menu {
                Button("Executed") { mettreAJourStatusPourSelection(nouveauStatus: "Executed") }
                Button("Engaged") { mettreAJourStatusPourSelection(nouveauStatus: "Engaged") }
                Button("Planned") { mettreAJourStatusPourSelection(nouveauStatus: "Planned") }
            } label: {
                Label("Change status", systemImage: "square.and.pencil")
            }
            .disabled(selectedTransactions.isEmpty)
            Button(role: .destructive, action: {
                supprimerTransactionsSelectionnees()
            }) {
                Label("Remove", systemImage: "trash")
            }
            .disabled(selectedTransactions.isEmpty)
            .padding()
        }
        .popover(isPresented: $showTransactionInfo, arrowEdge: .top) {
            if let index = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
                TransactionDetailView(currentSectionIndex: index, selectedTransaction: $selectedTransactions)
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                Text("Error: Transaction not found in the list.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        // Keyboard shortcut: Cmd+A to select all transactions, Escape to deselect all
        .onAppear {
            backgroundColor = isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor)
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "a" {
                    // Tout sélectionner
                    for transaction in dataManager.listTransactions {
                        selectedTransactions.insert(transaction.id)
                    }
                    transactionManager.selectedTransactions = dataManager.listTransactions
                    return nil
                }
                
                if event.keyCode == 53 { // Escape key
                    // Tout désélectionner
                    selectedTransactions.removeAll()
                    transactionManager.selectedTransaction = nil
                    transactionManager.selectedTransactions = []
                    return nil
                }
                
                return event
            }
        }
    }
    
    @ViewBuilder
    func verticalDivider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 2, height: 20)
            .padding(.horizontal, 2)
    }
    
    private func transaction(for id: UUID) -> EntityTransactions? {
        _ = selectedTransactions.compactMap { id in
            transaction(for: id)
        }
        return dataManager.listTransactions.first { $0.id == id }
    }
    
    private func toggleSelection() {
        let isCommand = NSEvent.modifierFlags.contains(.command)
        let isShift = NSEvent.modifierFlags.contains(.shift)
        
        if isShift, let lastID = transactionManager.lastSelectedTransactionID,
           let lastIndex = dataManager.listTransactions.firstIndex(where: { $0.id == lastID }),
           let currentIndex = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
            
            let range = lastIndex < currentIndex ? lastIndex...currentIndex : currentIndex...lastIndex
            let idsInRange = dataManager.listTransactions[range].map { $0.id }
            selectedTransactions.formUnion(idsInRange)
            
        } else if isCommand {
            if selectedTransactions.contains(transaction.id) {
                selectedTransactions.remove(transaction.id)
            } else {
                selectedTransactions.insert(transaction.id)
            }
            transactionManager.lastSelectedTransactionID = transaction.id
            
        } else {
            selectedTransactions.removeAll()
            selectedTransactions.insert(transaction.id)
            transactionManager.lastSelectedTransactionID = transaction.id
        }
        
        if let firstSelectedId = selectedTransactions.first {
            transactionManager.selectedTransaction = dataManager.listTransactions.first { $0.id == firstSelectedId }
        }
        transactionManager.selectedTransactions = dataManager.listTransactions.filter { selectedTransactions.contains($0.id) }
        transactionManager.isCreationMode = false
    }
    
    private func supprimerTransactionsSelectionnees() {
        withAnimation {
            // Copie locale des éléments à supprimer
            let transactionsToDelete = dataManager.listTransactions.filter { selectedTransactions.contains($0.id) }

            // Supprime du contexte si non déjà supprimé
            for transaction in transactionsToDelete {
                if !transaction.isDeleted {
                    modelContext.delete(transaction)
                }
            }

            // Vide la sélection
            selectedTransactions.removeAll()
            dataManager.loadTransactions()
        }
    }
    private func mettreAJourStatusPourSelection(nouveauStatus: String) {
        withAnimation {
            let selected = dataManager.listTransactions.filter { selectedTransactions.contains($0.id) }
            let status = StatusManager.shared.find(name: nouveauStatus)!
            for transaction in selected {
                transaction.status = status
            }
        }
    }
}
