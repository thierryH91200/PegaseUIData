//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData

// Gestionnaire de données pour les carnets de chèques
final class ListDataManager: ObservableObject {
    @Published var listTransactions: [EntityTransactions]? {
        didSet {
            // Sauvegarde automatique dès qu'une modification est détectée
            saveChanges()
        }
    }
    
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
}

struct ListTransactions: View {
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var dataManager       = ListDataManager()

    @Binding var isVisible: Bool
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: soldeBanque, planned: soldeReel, engaged: soldeFinal)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .task {
                    await performTrueTask()
                }

            ContentView10000( selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
                .environmentObject(colorManager) // Injecté ici
                .environmentObject(currentAccountManager)
                .environmentObject(dataManager)

                .frame(minWidth: 200, minHeight: 300)
            Spacer()
        }
        .onChange(of: colorManager.selectedColorType) { old, new in
        }
        .onAppear() {
            balanceCalculation()
        }
    }
    private func performTrueTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
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
        guard let transactions = dataManager.listTransactions, !transactions.isEmpty else {
            return
        }
        
        let count = transactions.count
        
        // Calcul des soldes transaction par transaction
        for index in stride(from: count - 1, to: -1, by: -1) {
            let transaction = transactions[index]
            
            let status = Int(transaction.status!.type)
            
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
            .environmentObject(colorManager) // Passe l'objet aux sous-vues
            .navigationTitle("My Transactions")
            .onAppear {
                setupDataManager()
                allTransactions = ListTransactionsManager.shared.getAllDatas()
            }
            .onChange(of: colorManager.selectedColorType) { old, new in
            }
            .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
                // Mise à jour de la liste en cas de changement de compte
                dataManager.listTransactions = nil
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
        allTransactions = dataManager.listTransactions ?? []
    }
}

// MARK: TransactionsListView
struct TransactionsListView: View {
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent

    let data: [TransactionsByYear100]
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool

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
                        .environmentObject(colorManager) // Passe l'environnement aux sous-vues
                }
            }
            .listStyle(.inset)
            .frame(minWidth: 700, minHeight: 400)
        }
    }
}

// MARK: YearSectionView
struct YearSectionView: View {
    @EnvironmentObject var colorManager: ColorManager // Injecté par le parent

    let yearGroup: TransactionsByYear100
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool

    
    var body: some View {
        Section(header: Text("Year \(yearGroup.year)")
                    .font(.headline)
                    .foregroundColor(.blue)
        ) {
            ForEach(yearGroup.months) { monthGroup in
                MonthDisclosureGroupView(monthGroup: monthGroup, year: yearGroup.year, selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
                    .environmentObject(colorManager) // Passe l'objet aux sous-vues
            }
        }
    }
}

// MARK: MonthDisclosureGroupView
struct MonthDisclosureGroupView: View {
    let monthGroup: TransactionsByMonth100
    let year: String
    @EnvironmentObject var colorManager: ColorManager
    
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool

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
                            isCreationMode = false
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

// MARK: TransactionRowView
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
                    
                    // Status
                    Text(statusText)
                        .foregroundColor(colorManager.colorForTransaction(transaction))
                    
                    // Solde (si vous voulez l’afficher)
                    Text(transaction.solde != nil ? String(format: "%.2f", transaction.solde!) : "—")
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
        guard let s = transaction?.status?.type else { return "Inconnu" }
        switch s {
        case 0: return String(localized: "Engaged")
        case 1: return String(localized: "Executed")
        case 2: return String(localized: "Planned")
        default: return "Other"
        }
    }

    private var statusColor: Color {
        guard let s = transaction?.status?.type else { return .gray }
        
        switch s {
        case 0: return .orange
        case 1: return .green
        case 2: return .red
        default: return .blue
        }
    }
}

