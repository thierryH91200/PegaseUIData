//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData


struct ListTransactionsView100: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isVisible: Bool
    @State private var selectedTransactions: Set<UUID> = []

    var body: some View {
        VStack {
#if DEBUG
            Button("Load demo data") {
                loadDemoData()
            }
            .textCase(.lowercase) // ← empêche SwiftUI de mettre en majuscules
            .padding(.bottom)
#endif
            ListTransactions200(isVisible: $isVisible, selectedTransactions: $selectedTransactions)
                .padding()
                .task {
                    await performFalseTask()
                }
                .onReceive(NotificationCenter.default.publisher(for: .loadDemoRequested)) { _ in
                    loadDemoData()
                }
                .onReceive(NotificationCenter.default.publisher(for: .resetDatabaseRequested)) { _ in
                    resetDatabase()
                }
        }
    }
    
    @MainActor
    func resetDatabase() {
        let transactions = ListTransactionsManager.shared.getAllDatas()
        
        for transaction in transactions {
            modelContext.delete(transaction)
        }

        try? modelContext.save()
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
    }
    @MainActor
    func loadDemoData() {
        let demoTransactions: [(String, Double, Int)] = [
            ("Achat supermarché", -45.60, 2),
            ("Salaire", 2000.00, 0),
            ("Facture électricité", -120.75, 1),
            ("Virement reçu", 350.00, 2),
            ("Abonnement streaming", -12.99, 1)
        ]

    }
}

struct ListTransactions200: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
    @EnvironmentObject private var dataManager           : ListDataManager
    @EnvironmentObject private var colorManager          : ColorManager
    
    @Binding var isVisible: Bool
    
    @State private var refresh = false
    @State private var currentSectionIndex: Int = 0

    @Binding var selectedTransactions: Set<UUID>
    
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0
    
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: soldeBanque, planned: soldeReel, engaged: soldeFinal)
                .frame(maxWidth: .infinity, maxHeight: 100)
            
            VStack {
                Text("\(compteCurrent?.name ?? "Aucun compte courant" )")

                Text(String(localized: "Selections : \(selectedTransactions.count) transaction(s)"))
                    .padding()
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.windowBackgroundColor))
            
            NavigationView {
                
                GeometryReader { geometry in
                    let width = max(800, geometry.size.width > 0 ? geometry.size.width : 800) // Sécurisation

                    List {
                        // Titres des colonnes
                        HStack {
                            Text("Date operation").bold().frame(width: 120, alignment: .leading)
                            Text("Date of pointing").bold().frame(width: 120, alignment: .leading)
                            Text("Comment").bold().frame(width: 150, alignment: .leading)
                            Text("Rubric").bold().frame(width: 100, alignment: .leading)
                            Text("Category").bold().frame(width: 100, alignment: .leading)
                            Text("Bank Statement").bold().frame(width: 120, alignment: .leading)
                            Text("Check Number").bold().frame(width: 120, alignment: .leading)
                            Text("Status").bold().frame(width: 100, alignment: .leading)
                            Text("Payment Mode").bold().frame(width: 120, alignment: .leading)
                            Text("Amount").bold().frame(width: 100, alignment: .trailing)
                        }
                        .padding(.vertical)
                        OperationRow(selectedTransactions: $selectedTransactions)
                    }
                    .frame(minWidth: 800, maxWidth: 1200) // Prévenir les valeurs invalides
                    .id(refresh)
                }
                .background(Color.white) // Ajoute un fond blanc derrière GeometryReader
            }
        }
        .onChange(of: colorManager.colorChoix) { old, new in
        }
        .onChange(of: currentAccountManager.currentAccount) { old, new in
            print("Changement de compte détecté: \(String(describing: new))")
            loadTransactions()
            
            withAnimation {
                refresh.toggle()
            }
        }
        .onAppear() {
            balanceCalculation()
        }
    }
    
    @MainActor
    func loadTransactions() {
        dataManager.listTransactions = ListTransactionsManager.shared.getAllDatas(ascending: false)
    }
    
    @MainActor
    func resetDatabase(using context: ModelContext) {
        let transactions = ListTransactionsManager.shared.getAllDatas()
        
        for transaction in transactions {
            context.delete(transaction)
        }

        try? context.save()
        loadTransactions()
        balanceCalculation()
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

struct YearGroup {
    var year: String
    var monthGroups: [MonthGroup]
}

struct MonthGroup {
    var month: String
    var transactions: [EntityTransactions]
}


// Exemple d'extension pour formater les dates
extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

func formatPrice(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency // format monétaire
    formatter.locale = Locale.current // devise de l'utilisateur
    let format = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    return format
}
