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
    @State var selectedTransaction: EntityTransactions?
    @State var isCreationMode: Bool = true
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: soldeBanque, planned: soldeReel, engaged: soldeFinal)
                .frame(maxWidth: .infinity, maxHeight: 100)
            
            ContentView10000( selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
                .frame(minWidth: 200, minHeight: 300)
            
            Spacer()
        }
        .onChange(of: colorManager.selectedColorType) { old, new in
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
//        , !transactions.isEmpty else { return }
        
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
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
    
    var body: some View {
        let grouped = groupTransactionsByYear(transactions: allTransactions)
        TransactionsListView(data: grouped, selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
            .navigationTitle("My Transactions")
            .onAppear {
                setupDataManager()
                allTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
            }
            .onChange(of: dataManager.listTransactions) { _, _ in
                allTransactions = dataManager.listTransactions
            }
            .onChange(of: colorManager.selectedColorType) { old, new in
            }
            .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
                // Mise à jour de la liste en cas de changement de compte
//                dataManager.listTransactions = []
                refreshData()
            }
    }
    // Configure le gestionnaire de données
    private func setupDataManager() {
        ListTransactionsManager.shared.configure(with: modelContext)
        dataManager.configure(with: modelContext)
        
        if currentAccountManager.currentAccount != nil {
            dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas()
        }
    }
    
    // Rafraîchit la liste des transactions
    private func refreshData() {
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas()
        allTransactions = dataManager.listTransactions
    }
}

// MARK: TransactionsListView
struct TransactionsListView: View {
    @EnvironmentObject var dataManager: ListDataManager
    
    let data: [TransactionsByYear100]
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
    
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
            
            List(selection: $selectedTransaction) {
                ForEach(data) { yearGroup in
                    YearSectionView(yearGroup: yearGroup, selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
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
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
    
    var body: some View {
        Section(header: Text("Year \(yearGroup.year)")
            .font(.headline)
            .foregroundColor(.blue)
        ) {
            ForEach(yearGroup.months) { monthGroup in
                MonthDisclosureGroupView(monthGroup: monthGroup, year: yearGroup.year)
            }
        }
    }
}

// MARK: MonthDisclosureGroupView
struct MonthDisclosureGroupView: View {
    @EnvironmentObject var dataManager: ListDataManager
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    @State private var showTransactionInfo : Bool = false
    @State private var selectedTransaction: EntityTransactions?
    
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
                TransactionsRowsView(transactions: monthGroup.transactions,
                                     selectedTransaction: $selectedTransaction,
                                     showTransactionInfo: $showTransactionInfo )
                .sheet(isPresented: $showTransactionInfo) {
                    if let selected = selectedTransaction {
                        TransactionDetailView(transaction: selected)
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
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var dataManager: ListDataManager
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    let transactions: [EntityTransactions]?
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var showTransactionInfo: Bool
    
    var body: some View {
        VStack {
            if let transactions = transactions {
                ForEach(transactions, id: \.id) { transaction in
                    let isSelected = transactionManager.selectedTransaction?.id == transaction.id
                    
                    Button {
                        // Synchroniser les deux états de sélection
                        transactionManager.selectedTransaction = transaction
                        selectedTransaction = transaction
                        transactionManager.isCreationMode = false
                    } label: {
                        TransactionRow(
                            transaction: transaction,
                            isSelected: isSelected,
                            colorManager: colorManager
                        ) {
                            deleteTransaction(transaction)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            selectedTransaction = transaction
                            showTransactionInfo = true
                        } label: {
                            Label("Information", systemImage: "info.circle")
                        }
                        
                        Button(role: .destructive) {
                            deleteTransaction(transaction)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        // Déplacer le sheet vers la vue parente
        // Ce sheet devrait être attaché à la vue parente, pas à l'intérieur de cette vue
    }
    

    /// ✅ Nouvelle fonction pour sélectionner correctement une transaction
    private func selectTransaction(_ transaction: EntityTransactions) {
        DispatchQueue.main.async {
            selectedTransaction = transaction
            print("📌 [selectTransaction] Transaction sélectionnée : \(transaction.id.uuidString)")
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
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas()
    }
}

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    let transaction: EntityTransactions
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transaction Details")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            HStack {
                Text("Create at :")
                    .bold()
                Spacer()
                Text(transaction.createAt != nil ? Self.dateFormatter.string(from: transaction.createAt!) : "—")
            }
            HStack {
                Text("Update at :")
                    .bold()
                Spacer()
                Text(transaction.updatedAt != nil ? Self.dateFormatter.string(from: transaction.updatedAt!) : "—")
            }

            Divider()

            HStack {
                Text("Amount :")
                    .bold()
                Spacer()
                Text("\(String(format: "%.2f", transaction.amount)) €")
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
            }
            Divider()
            
            HStack {
                Text("Date of pointing :")
                    .bold()
                Spacer()
                Text(transaction.datePointage != nil ? Self.dateFormatter.string(from: transaction.datePointage!) : "—")
            }
            HStack {
                Text("Date operation :")
                    .bold()
                Spacer()
                // Correction ici - vous utilisiez datePointage au lieu de dateOperation
                Text(transaction.dateOperation != nil ? Self.dateFormatter.string(from: transaction.dateOperation!) : "—")
            }
            HStack {
                Text("Payment method :")
                    .bold()
                Spacer()
                Text(transaction.paymentMode?.name ?? "—")
            }
            HStack {
                Text(" Bank statement :")
                    .bold()
                Spacer()
                Text(String(transaction.bankStatement))
            }
            
            HStack {
                Text("Statut :")
                    .bold()
                Spacer()
                Text(transaction.status?.name ?? "N/A")
            }
            Divider()
            
            // Section pour les sous-opérations
            if let premiereSousOp = transaction.sousOperations.first {
                HStack {
                    Text("Comment :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.libelle ?? "Sans libellé")
                }
                HStack {
                    Text("Rubric :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.category?.rubric?.name ?? "N/A")
                }
                HStack {
                    Text("Category :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.category?.name ?? "N/A")
                }
                HStack {
                    Text("Amount :")
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", premiereSousOp.amount)) €")
                        .foregroundColor(premiereSousOp.amount >= 0 ? .green : .red)
                }
            } else {
                Text("No sub-operations available")
                    .italic()
                    .foregroundColor(.gray)
            }
            
            // Si vous avez plusieurs sous-opérations, vous pourriez ajouter une liste ici
            
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    transactionManager.selectedTransaction = nil
                    dismiss()
                }) {
                    Text("Close")
                        .frame(width: 100)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }    
}

struct TransactionRow: View {
    let transaction: EntityTransactions
    let isSelected: Bool
    let colorManager: ColorManager
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
                .frame(width: 90, alignment: .leading)
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
            
            Text(transaction.checkNumber)
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
    
    
