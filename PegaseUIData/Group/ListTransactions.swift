//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData

// Gestionnaire de données pour les listTransactions
final class ListDataManager: ObservableObject {
    @Published var listTransactions: [EntityTransactions] = []
     
    private var modelContext: ModelContext?
    
    // Configure le contexte de modèle pour la gestion des données
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // Sauvegarde les modifications dans SwiftData
    func saveChanges() {
        guard let modelContext = modelContext else {
            print("Le contexte de modèle n'est pas initialisé.")
            return
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
    
    @MainActor func deleteTransaction(_ transaction: EntityTransactions) {
        guard let modelContext = modelContext else { return }
               
        modelContext.delete(transaction)
        
        // Rafraîchir complètement la liste après suppression
        saveChanges()
        loadTransactions()  // Recharger la liste des transactions
    }
    
    @MainActor
    func loadTransactions() {
        
        self.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
        objectWillChange.send()
    }
}

struct ListTransactionsView: View {
    
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @Binding var isVisible: Bool
    
    var body: some View {
        ListTransactions()
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

struct ListTransactions: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
    @EnvironmentObject private var dataManager           : ListDataManager
    @EnvironmentObject private var colorManager          : ColorManager
    
    @State var isVisible: Bool = true
    
//    @State var selectedTransactions :  Set<UUID> = []
    @State var isCreationMode: Bool = true
    
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: soldeBanque, planned: soldeReel, engaged: soldeFinal)
                .frame(maxWidth: .infinity, maxHeight: 100)
            
            ContentView10000( isCreationMode: $isCreationMode)
                .frame(minWidth: 200, minHeight: 300)
            
            Spacer()
        }
        .onChange(of: colorManager.colorChoix) { old, new in
        }
        .onAppear() {
            balanceCalculation()
        }
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
}

// MARK: ContentView10000
struct ContentView10000: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: ListDataManager
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent
    
    @State private var allTransactions: [EntityTransactions] = []
    
    @State private var selectedTransactions = Set<EntityTransactions.ID>()
    @Binding var isCreationMode: Bool
    
    var body: some View {
        let grouped = groupTransactionsByYear(transactions: allTransactions)
        
        TransactionsListView(data: grouped, selectedTransactions: $selectedTransactions, isCreationMode: $isCreationMode)
            .navigationTitle("My Transactions")
            .onAppear {
                setupDataManager()
                allTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
            }
            .onChange(of: dataManager.listTransactions) { _, _ in
                allTransactions = dataManager.listTransactions
            }
            .onChange(of: colorManager.colorChoix) { old, new in
            }
            .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
                refreshData()
            }
    }
    // Configure le gestionnaire de données
    private func setupDataManager() {
        ListTransactionsManager.shared.configure(with: modelContext)
        dataManager.configure(with: modelContext)
        
        if currentAccountManager.currentAccount != nil {
            dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
        }
    }
    
    // Rafraîchit la liste des transactions
    private func refreshData() {
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
        allTransactions = dataManager.listTransactions
    }
}

// MARK: TransactionsListView
struct TransactionsListView: View {
    @EnvironmentObject var dataManager: ListDataManager
    
    let data: [TransactionsByYear100]
    
    @Binding var selectedTransactions :  Set<EntityTransactions.ID>
    @Binding var isCreationMode: Bool
    
    var transactions: [EntityTransactions] = [] // Charge tes transactions ici

    var body: some View {
        VStack(spacing: 0) {
            // En-tête des colonnes
            HStack {
                Text("Pointing Date")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Transaction Date")
                    .frame(width: 90, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Comment")
                    .frame(width: 150, alignment: .leading)
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
                Text("Check")
                    .frame(width: 90, alignment: .trailing)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Status")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(Rectangle().frame(width: 1).foregroundColor(.gray), alignment: .trailing)
                Text("Amount")
                    .frame(width: 90, alignment: .trailing)
            }
            .font(.headline)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            
            Divider()
            
            List(selection: $selectedTransactions) {
                ForEach(data) { yearGroup in
                    YearSectionView(yearGroup: yearGroup,
                                    selectedTransactions: $selectedTransactions,
                                    isCreationMode: $isCreationMode)
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 700, minHeight: 400)
        }
    }
}

// MARK: YearSectionView
struct YearSectionView: View {
    
    let yearGroup: TransactionsByYear100
    @Binding var selectedTransactions: Set<EntityTransactions.ID>
    @Binding var isCreationMode: Bool
    
    var body: some View {
        Section(header: Text("Year \(yearGroup.year)")
            .font(.headline)
            .foregroundColor(.blue)
        ) {
            ForEach(yearGroup.months) { monthGroup in
//                MonthDisclosureGroupView(year: yearGroup.year,
//                                         selectedTransactions: $selectedTransactions)
                MonthDisclosureGroupView(
                    transactions: monthGroup.transactions,
                    showTransactionInfo: false, // Si c'est une @State var, passe `false` par défaut
                    selectedTransactions: $selectedTransactions,
                    monthGroup: monthGroup,
                    year: yearGroup.year
                )
            }
        }
    }
}

// MARK: MonthDisclosureGroupView
struct MonthDisclosureGroupView: View {
    @EnvironmentObject var dataManager: ListDataManager
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    var transactions: [EntityTransactions] = [] // Charge tes transactions ici

    @State var showTransactionInfo : Bool
    @Binding var selectedTransactions: Set<EntityTransactions.ID>
    
    let monthGroup: TransactionsByMonth100
    let year: String
    
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
                TransactionsRowsView(
                    transactions: monthGroup.transactions,
                    selectedTransactions: $selectedTransactions,
                    showTransactionInfo: $showTransactionInfo )
                
//                .onChange(of: selectedTransaction) { old, newValue in
//                    print("Nouvelle transaction sélectionnée : \(newValue?.libelle ?? "N/A")")
//                }

                .sheet(isPresented: $showTransactionInfo) {
                    if let firstSelectedID = selectedTransactions.first,
                       let selectedTransaction = dataManager.listTransactions.first(where: { $0.id == firstSelectedID }) {
                        TransactionDetailView(transaction: selectedTransaction)
                            .frame(minWidth: 400, minHeight: 300)
                    } else {
                        Text("No transaction selected")
                            .frame(minWidth: 400, minHeight: 300)
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

// MARK: TransactionsRowsView
struct TransactionsRowsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataManager: ListDataManager
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    let transactions: [EntityTransactions]?
    
    @Binding var selectedTransactions: Set<EntityTransactions.ID>
    @Binding var showTransactionInfo: Bool
    
    var body: some View {
        VStack {
//            if let transactions = transactions {
//                ForEach(transactions, id: \.id) { transaction in
                    
//                    let isSelected = transactionManager.selectedTransactions.map { $0.id == transaction.id } ?? false
//                    let isSelected = transactionManager.selectedTransactions.contains(transaction.id)
//                    let isSelected = true
//                    Button {
//                        toggleSelection(transaction)
//                    } label: {
//                        TransactionRow(
//                            transaction: transaction,
//                            isSelected: isSelected
//                        ) {
//                            deleteTransaction(transaction)
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .contextMenu {
//                        Button {
//                            // Synchroniser les deux états de sélection
//                            transactionManager.selectedTransaction = transaction
//                            selectedTransactions = transaction
//                            transactionManager.isCreationMode = false
//                        } label: {
//                            TransactionRow(
//                                transaction: transaction,
//                                isSelected: isSelected,
//                            ) {
//                                deleteTransaction(transaction)
//                            }
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .contextMenu {
//                            Button {
//                                selectedTransactions = transaction
//                                showTransactionInfo = true
//                            } label: {
//                                Label("Information", systemImage: "info.circle")
//                            }
//                            
//                            Button(role: .destructive) {
//                                deleteTransaction(transaction)
//                            } label: {
//                                Label("Delete", systemImage: "trash")
//                            }
//                        }
//                    }
//                }
//            }
        }
    }
    
    /// ✅ Fonction pour gérer la sélection multiple
    func toggleSelection(_ transaction: EntityTransactions) {
        if NSEvent.modifierFlags.contains(.command) {
            // Cmd + Clic : Ajoute ou enlève une sélection
            if selectedTransactions.contains(transaction.id) {
                selectedTransactions.remove(transaction.id)
            } else {
                selectedTransactions.insert(transaction.id)
            }
        } else if NSEvent.modifierFlags.contains(.shift) {
            // Shift + Clic : Sélection en continu (expliqué plus bas)
            if let first = transactions?.first,
               let firstIndex = transactions?.firstIndex(of: first),
               let lastIndex = transactions?.firstIndex(of: transaction) {
                let range = firstIndex...lastIndex
                let selectedRange = transactions?[range].map { $0.id } ?? []
                selectedTransactions.formUnion(selectedRange)
            }
        } else {
            // Clic normal : Sélection unique
            selectedTransactions = [transaction.id]
        }
    }
    
    @MainActor
    func deleteTransaction(_ transaction: EntityTransactions) {
        
        modelContext.delete(transaction)
        
        do {
            try modelContext.save()
            if let index = dataManager.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
                dataManager.listTransactions.remove(at: index)
            }
            loadTransactions()
        } catch {
            print("❌ Erreur lors de la suppression de la transaction : \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadTransactions() {
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
    }
}

struct TransactionRow: View {
    
    @EnvironmentObject private var colorManager : ColorManager

    let transaction: EntityTransactions
    let isSelected: Bool
    let deleteAction: () -> Void
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            let foregroundColor = colorManager.colorForTransaction(transaction)
            
            Text(transaction.datePointage != nil ? Self.dateFormatter.string(from: transaction.datePointage!) : "—")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(foregroundColor)
            
            Text(transaction.dateOperation != nil ? Self.dateFormatter.string(from: transaction.dateOperation!) : "—")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(foregroundColor)
            
            Text(transaction.sousOperations.first?.libelle ?? "—")
                .frame(width: 150, alignment: .leading)
                .foregroundColor(foregroundColor)
            
            Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(foregroundColor)
            
            Text(transaction.sousOperations.first?.category?.name ?? "—")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(foregroundColor)
            Text(transaction.paymentMode?.name ?? "—")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(foregroundColor)
            Text(String(format: "%.2f", transaction.bankStatement))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(foregroundColor)
            
            Text(String(format: "%.2f", transaction.amount))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(transaction.amount >= 0 ? .green : .red)
            
            Text(transaction.checkNumber == "0" ? transaction.checkNumber : " "  )
                .frame(width: 80, alignment: .leading)
                .foregroundColor(foregroundColor)
            
            Text(transaction.status?.name ?? "N/A")
                .frame(width: 90, alignment: .leading)
                .monospacedDigit()
                .foregroundColor(foregroundColor)
            
            Text(transaction.solde != nil ? String(format: "%.2f", transaction.solde!) : "—")
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(foregroundColor)
            
            Spacer()
            
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
            .frame(width: 30, height: 30)
        }
        .padding(.vertical, 2)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
    
