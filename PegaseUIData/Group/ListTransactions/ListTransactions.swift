//
//  ListTransactions.swift
//  PegaseUIData
//
//  Created by thierryH24 on 11/10/2025.
//

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
    
    @State private var selectedTransactions: Set<UUID> = []
    @State private var refreshTick: Int = 0

    @Binding var dashboard: DashboardState
    var injectedTransactions: [EntityTransaction]? = nil

    private var transactions: [EntityTransaction] { injectedTransactions ?? ListTransactionsManager.shared.listTransactions }

    var body: some View {
        
        VStack(spacing: 0) {
                        
            #if DEBUG
                        Button("Load demo data") {
                            loadDemoData()
                        }
                        .textCase(.lowercase) // empêche SwiftUI de mettre en majuscules
                        .padding(.bottom)
            #endif
            
            Divider()
            ListTransactions200(
                injectedTransactions: injectedTransactions,
                dashboard: $dashboard,
                selectedTransactions: $selectedTransactions
            )
            .transaction { $0.animation = nil }
            .id(refreshTick)
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
            .onReceive(NotificationCenter.default.publisher(for: .transactionsAddEdit)) { _ in
                printTag("transactionsAddEdit notification received")
                DispatchQueue.main.async {
                    _ = ListTransactionsManager.shared.getAllData()
                    withAnimation(nil) {
                        selectedTransactions.removeAll()
                    }
                    updateSummary()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionsImported)) { _ in
                printTag("transactionsImported notification received")
                DispatchQueue.main.async {
                    _ = ListTransactionsManager.shared.getAllData()
                    SwiftUI.withTransaction(.init(animation: nil)) {
                        selectedTransactions.removeAll()
                    }
                    updateSummary()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionsSelectionChanged)) { _ in
                updateSummary()
                SwiftUI.withTransaction(.init(animation: nil)) {
                    refreshTick &+= 1
                }
            }

            .onReceive(NotificationCenter.default.publisher(for: .treasuryListNeedsRefresh)) { _ in
                DispatchQueue.main.async {
                    updateSummary()
                }
            }
            .onChange(of: injectedTransactions ?? []) { _, _ in
                DispatchQueue.main.async {
                    updateSummary()
                }
            }
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    guard event.modifierFlags.contains(.command), let characters = event.charactersIgnoringModifiers else {
                        return event
                    }
                    
                    switch characters {
                    case "c":
                        NotificationCenter.default.post(name: .copySelectedTransactions, object: nil)
                        return nil
                    case "x":
                        NotificationCenter.default.post(name: .cutSelectedTransactions, object: nil)
                        return nil
                    case "v":
                        NotificationCenter.default.post(name: .pasteSelectedTransactions, object: nil)
                        return nil
                    default:
                        return event
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    DispatchQueue.main.async {
                        updateSummary()
                    }
                }
            }
        }
    }
    
    private func updateSummary() {
        // Calcule d'abord les valeurs
        let newExecuted = calculateExecuted()
        let newEngaged  = newExecuted + calculateEngaged()
        let newPlanned  = newEngaged  + calculatePlanned()

        // No-op si identiques (évite des commits inutiles)
        if dashboard.executed == newExecuted &&
           dashboard.engaged  == newEngaged  &&
           dashboard.planned  == newPlanned {
            return
        }

        // Ecritures coalisées et sans animation
        var tx = SwiftUI.Transaction()
        tx.disablesAnimations = true
        SwiftUI.withTransaction(tx) {
            dashboard.executed = newExecuted
            dashboard.engaged  = newEngaged
            dashboard.planned  = newPlanned
        }
    }
    
    @MainActor
    func resetDatabase() {
        let transactions = ListTransactionsManager.shared.getAllData()
        
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        try? modelContext.save()
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        await MainActor.run {
            dashboard.isVisible = true
        }
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
    
    func calculatePlanned() -> Double {
        transactions
            .filter { $0.status?.type == .planned }
            .map(\.amount)
            .reduce(0, +)
    }
    
    func calculateEngaged() -> Double {
        transactions
            .filter { $0.status?.type == .inProgress }
            .map(\.amount)
            .reduce(0, +)
    }
    
    func calculateExecuted() -> Double {
        transactions
            .filter { $0.status?.type == .executed  }
            .map(\.amount)
            .reduce(0, +)
    }
}


struct YearGroup {
    var year: Int
    var monthGroups: [MonthGroup]
}

struct MonthGroup {
    var month: String
    var transactions: [EntityTransaction]
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


struct PriceText: View {
    let amount: Double

    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }
}

func cleanDouble(from string: String) -> Double {
    // Supprime les caractères non numériques sauf , et .
    let cleanedString = string.filter { "0123456789,.".contains($0) }
    
    // Convertir la virgule en point si nécessaire
    let normalized = cleanedString.replacingOccurrences(of: ",", with: ".")
    
    return Double(normalized) ?? 0.0
}

// Keyboard shortcut notifications
extension Notification.Name {
    static let copySelectedTransactions = Notification.Name("copySelectedTransactions")
    static let cutSelectedTransactions = Notification.Name("cutSelectedTransactions")
    static let pasteSelectedTransactions = Notification.Name("pasteSelectedTransactions")
    static let transactionsSelectionChanged = Notification.Name("transactionsSelectionChanged")
    static let treasuryListNeedsRefresh = Notification.Name("treasuryListNeedsRefresh")
}

//
//  ListTransactions110.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers


struct OperationRow: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
//    @EnvironmentObject private var colorManager          : ColorManager
    
    @Binding var selectedTransactions: Set<UUID>
    var transactions: [EntityTransaction]
    @State private var info: String = ""
    
    @State private var showFileImporter = false
    @State private var csvData: [[String]] = []
    @State private var columnMapping: [String: Int] = [:] // Associe les attributs aux colonnes

    // Attributs disponibles
    let transactionAttributes = [String(localized:"Pointage Date"),
                                 String(localized:"Operation Date"),
                                 String(localized:"Comment"),
                                 String(localized:"Rubric"),
                                 String(localized:"Category"),
                                 String(localized:"Payment method"),
                                 String(localized:"Status"),
                                 String(localized:"Amount")]

    // private var transactions: [EntityTransaction] { ListTransactionsManager.shared.listTransactions }
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
        List(selection: $selectedTransactions) {
            let grouped = groupTransactionsByYear(transactions: transactions)
            let visibleTransactions = grouped.flatMap { $0.monthGroups.flatMap { $0.transactions } }
            ForEach(grouped, id: \.year) { yearGroup in
                Section(header:
                    Label("Year : \(yearGroup.year)", systemImage: "calendar")
                        .font(.headline)
                        .contentShape(Rectangle()) // 👈 rend toute la zone réactive
                        .buttonStyle(PlainButtonStyle()) // 👈 évite les interférences
                ) {
                    ForEach(yearGroup.monthGroups, id: \.month) { monthGroup in
                        let key = "month_\(yearGroup.year)_\(monthGroup.month)"
                        DisclosureGroup(isExpanded: isExpanded(for: key)) {
                            ForEach(monthGroup.transactions) { transaction in
                                TransactionLigne(transaction: transaction,
                                                 selectedTransactions: $selectedTransactions,
                                                 visibleTransactions: visibleTransactions)
                                    .foregroundColor(.black)
                                    .contentShape(Rectangle())
                                    .background(Color.clear)
                            }
                        } label: {
                            Label("Month : \(monthGroup.month)", systemImage: "calendar")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                                .contentShape(Rectangle()) // 👈 rend toute la zone réactive
                                .buttonStyle(PlainButtonStyle()) // 👈 évite les interférences
                        }
                    }
                }
            }
        }
        .frame(minHeight: 800)
        .contextMenu {
            Button {
                showFileImporter = true
            } label: {
                Label("Import a CSV file", systemImage: "tray.and.arrow.down")
            }
            Button {
                printTag("Exporter les transactions")
            } label: {
                Label("Export", systemImage: "tray.and.arrow.up")
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
        .onChange(of: transactions.map { $0.id }) { _, _ in
            // Ouvre par défaut les mois pour la nouvelle source de données
            for yearGroup in groupTransactionsByYear(transactions: transactions) {
                for monthGroup in yearGroup.monthGroups {
                    let key = "month_\(yearGroup.year)_\(monthGroup.month)"
                    if disclosureStates[key] == nil {
                        disclosureStates[key] = true
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let data = readCSV(from: url) {
                    csvData = data
                }
            case .failure(let error):
                printTag("Erreur de sélection de fichier : \(error.localizedDescription)")
            }
        }
        if !csvData.isEmpty {
            Text("CSV Preview").font(.headline)
            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    TableView(data: csvData)
                }
                .frame(minWidth: CGFloat((csvData.first?.count ?? 1) * 200), alignment: .leading)
                .background(Color.clear)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Match the columns :").font(.headline)
            ForEach(transactionAttributes, id: \.self) { attribute in
                Picker(attribute, selection: Binding(
                    get: { columnMapping[attribute] ?? -1 },
                    set: { columnMapping[attribute] = $0 }
                )) {
                    let csvData1 = csvData.dropFirst()
                    Text("Ignore").tag(-1)
                    ForEach(0..<(csvData1.first?.count ?? 0), id: \.self) { index in
                        Text("Column \(index)").tag(index)
                    }
                }
                .frame(width: 300)
                .pickerStyle(MenuPickerStyle())
            }

            HStack(spacing: 20) {
                Button(action: {
                    importCSVTransactions(context: modelContext)
                    dismiss()
                }) {
                    Label("Import", systemImage: "tray.and.arrow.down")
                        .padding()
                        .background( Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(columnMapping.isEmpty)
                        .fixedSize()
                }

                Button(action: {
                    dismiss()
                }) {
                    Label("Cancel", systemImage: "stop")
                        .padding()
                        .background( Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(columnMapping.isEmpty)
                        .fixedSize()
                }
            }
            .padding(.top, 10)
        }
    }
    
    // Fonctions utilitaires
    func getString(from row: [String], index: Int?) -> String {
        guard let index = index, index >= 0, index < row.count else { return "" }
        return row[index]
    }

    func getDouble(from row: [String], index: Int?) -> Double {
        guard let index = index, index >= 0, index < row.count else { return 0.0 }
        let value = row[index].replacingOccurrences(of: String(","), with: ".")
        return Double(value) ?? 0.0
    }

    func getDate(from row: [String], index: Int?) -> Date? {
        guard let index = index, index >= 0, index < row.count else { return Date().noon }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Ajuste selon le format de ton CSV
        return formatter.date(from: row[index])?.noon
    }
    func readCSV(from url: URL) -> [[String]]? {
        
        guard url.startAccessingSecurityScopedResource() else {
            printTag("⚠️ Impossible d'accéder au fichier (Security Scoped)")
            return nil
        }
        
        defer { url.stopAccessingSecurityScopedResource() } // Libérer l'accès à la fin
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            // Détecter le séparateur
            let separator: Character = content.contains(";") ? ";" : ","
            
            let parsedData = rows.map { $0.components(separatedBy: String(separator)) }
            return parsedData
        } catch {
            printTag("Erreur lors de la lecture du fichier CSV : \(error.localizedDescription)")
            return nil
        }
    }

    func importCSVTransactions(context: ModelContext) {
        guard !csvData.isEmpty else { return }
        
        let count = csvData.count
        printTag("Importation de \(count) transactions CSV.")
        
        let account = CurrentAccountManager.shared.getAccount()!

        let entityPreference = PreferenceManager.shared.getAllData(for: account)

        for row in csvData.dropFirst() { // Ignorer l'en-tête
            
            let datePointage =  getDate(from: row, index: columnMapping[String(localized:"Pointage Date")])  ?? Date().noon
            let dateOperation = getDate(from: row, index: columnMapping[String(localized:"Operation Date")]) ?? datePointage
            let libelle = getString(from: row, index: columnMapping[String(localized:"Comment")])
            
            let bankStatement = 0.0
            
            //            let rubric = getString(from: row, index: columnMapping[String(localized:"Rubric")])
            let category = getString(from: row, index: columnMapping[String(localized:"Category")])
            
            let entityCategory = CategoryManager.shared.find(name: category) ?? entityPreference?.category
            
            let paymentMode = getString(from: row, index: columnMapping[String(localized:"Payment method")])
            let entityModePaiement = PaymentModeManager.shared.find(name: paymentMode) ?? entityPreference?.paymentMode
            
            let status = getString(from: row, index: columnMapping[String(localized:"Status")])
            let entityStatus = StatusManager.shared.find(name: status) ?? entityPreference?.status
            
            let amount = getDouble(from: row, index: columnMapping[String(localized:"Amount")])
            
            let transaction = EntityTransaction()
            
            transaction.createAt  = Date().noon
            transaction.updatedAt = Date().noon
            
            transaction.dateOperation = dateOperation.noon
            transaction.datePointage  = datePointage.noon
            transaction.paymentMode   = entityModePaiement
            transaction.status        = entityStatus
            transaction.bankStatement = bankStatement
            transaction.checkNumber   = "0"
            transaction.account       = account
            
            let sousTransaction         = EntitySousOperation()
            sousTransaction.libelle     = libelle
            sousTransaction.amount      = amount
            sousTransaction.category    = entityCategory
            sousTransaction.transaction = transaction
            
            context.insert(sousTransaction)
            transaction.addSubOperation(sousTransaction)

            context.insert(transaction)
        }
        
        do {
            try context.save()
            printTag("Importation réussie 🎉")
        } catch {
            printTag("Erreur lors de l'enregistrement : \(error)")
        }
    }

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
            disclosureStates = loadedStates
            // Ouvre tous les mois par défaut s'ils ne sont pas enregistrés
            for yearGroup in groupTransactionsByYear(transactions: transactions) {
                for monthGroup in yearGroup.monthGroups {
                    let key = "month_\(yearGroup.year)_\(monthGroup.month)"
                    if disclosureStates[key] == nil {
                        disclosureStates[key] = true
                    }
                }
            }
        }
    }
    
    private func groupTransactionsByYear(transactions: [EntityTransaction]) -> [YearGroup] {
        var groupedItems: [YearGroup] = []
        let calendar = Calendar.current
        
        // Group transactions by year
        let groupedByYear = Dictionary(grouping: transactions) { (transaction) -> Int in
            let components = calendar.dateComponents([.year], from: transaction.datePointage)
            return components.year ?? 0
        }
        
        for (year, yearTransactions) in groupedByYear {
            var yearGroup = YearGroup(year: year, monthGroups: [])
            
            let groupedByMonth = Dictionary(grouping: yearTransactions) { (transaction) -> Int in
                let components = calendar.dateComponents([.month], from: transaction.datePointage)
                return components.month ?? 0
            }
            
            for (month, monthTransactions) in groupedByMonth.sorted(by: { $0.key > $1.key }) {
                let monthName = DateFormatter().monthSymbols[month - 1]
                let monthGroup = MonthGroup(month: monthName,
                                            //                                            transactions: monthTransactions.sorted(by: { $0.dateOperation > $1.dateOperation }))
                                            transactions: monthTransactions.sorted(by: { $0.datePointage > $1.datePointage }))
                
                yearGroup.monthGroups.append(monthGroup)
            }
            
            groupedItems.append(yearGroup)
        }
        return groupedItems
    }
}

//
//  ListTransactions120.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData


struct TransactionLigne: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var transactionManager   : TransactionSelectionManager
    @EnvironmentObject private var colorManager : ColorManager
    
    let transaction: EntityTransaction
    @Binding var selectedTransactions: Set<UUID>
    let visibleTransactions: [EntityTransaction]
    
    @State var showTransactionInfo: Bool = false
    @GestureState private var isShiftPressed = false
    @GestureState private var isCmdPressed = false

    @State private var showPopover = false
    @State private var inputText = ""

    @State private var backgroundColor = Color.clear
    
    var isSelected: Bool {
        selectedTransactions.contains(transaction.id)
    }
    
    var body: some View {
        let isSelected = selectedTransactions.contains(transaction.id)
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(transaction)
        
        HStack(spacing: 0) {
            Group {
                Text(transaction.datePointageString)
                    .frame(width: ColumnWidths.datePointage, alignment: .leading)
                verticalDivider()
                Text(transaction.dateOperationString)
                    .frame(width: ColumnWidths.dateOperation, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.libelle ?? "—")
                    .frame(width: ColumnWidths.libelle, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                    .frame(width: ColumnWidths.rubrique, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.category?.name ?? "—")
                    .frame(width: ColumnWidths.categorie, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.amountString ?? "—")
                    .frame(width: ColumnWidths.sousMontant, alignment: .leading)
                verticalDivider()
                Text(transaction.bankStatementString)
                    .frame(width: ColumnWidths.releve, alignment: .leading)
                verticalDivider()
                Text(transaction.checkNumber != "0" ? transaction.checkNumber : "—").frame(width: ColumnWidths.cheque, alignment: .leading)
                verticalDivider()
            }
            Group {
                Text(transaction.statusString)
                    .frame(width: ColumnWidths.statut, alignment: .leading)
                verticalDivider()
                Text(transaction.paymentModeString)
                    .frame(width: ColumnWidths.modePaiement, alignment: .leading)
                verticalDivider()
                Text(transaction.amountString)
                    .frame(width: ColumnWidths.montant, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(EdgeInsets()) // ⬅️ Supprime la marge à gauche des lignes
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.5) : backgroundColor)
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
            // Afficher les détails
            Button(action: {
                transactionManager.selectedTransaction = transaction
                transactionManager.isCreationMode = false
                showTransactionInfo = true
            }) {
                Label("Show details", systemImage: "info.circle")
            }
            // Liste des noms et couleurs des status
            let names = [ String(localized :"Planned"),
                          String(localized :"In progress"),
                          String(localized :"Executed") ]
            Menu {
                Button(names[0]) { mettreAJourStatusPourSelection(nouveauStatus: names[0]) }
                Button(names[1]) { mettreAJourStatusPourSelection(nouveauStatus: names[1]) }
                Button(names[2]) { mettreAJourStatusPourSelection(nouveauStatus: names[2]) }
            } label: {
                Label("Change status", systemImage: "square.and.pencil")
            }
            .disabled(selectedTransactions.isEmpty)
            
            let namesPayements = PaymentModeManager.shared.getAllNames()
            Menu {
                ForEach(namesPayements, id: \.self) { mode in
                    Button(mode) {
                        mettreAJourModePourSelection(nouveauMode: mode)
                    }
                }
            } label: {
                Label("Change Payment Mode", systemImage: "square.and.pencil")
            }
            .disabled(selectedTransactions.isEmpty)
            
            Menu {
                Button("New statement…") {
                    showPopover = true
                }
            } label: {
                Label("Bank statement", systemImage: "square.and.pencil")
            }
            
            Button(role: .destructive, action: {
                supprimerTransactionsSelectionnees()
            }) {
                Label("Remove", systemImage: "trash")
            }
            .disabled(selectedTransactions.isEmpty)
        }
        
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            VStack(spacing: 12) {
                Text("Create a statement")
                    .font(.headline)

                TextField("Statement number", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                HStack {
                    Button("Cancel") {
                        showPopover = false
                    }
                    Button("OK") {
                        print("Relevé saisi: \(inputText)")
                        mettreAJourRelevePourSelection(nouveauReleve: inputText)
                        showPopover = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(width: 250)
        }

        .popover(isPresented: $showTransactionInfo, arrowEdge: .top) {
            if let index = ListTransactionsManager.shared.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
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
            backgroundColor = isSelected ? Color.accentColor.opacity(0.2) : Color.clear
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "a" {
                    // Tout sélectionner
                    for transaction in ListTransactionsManager.shared.listTransactions {
                        selectedTransactions.insert(transaction.id)
                    }
                    transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions
                    return nil
                }
                
                if event.keyCode == 53 { // Escape key
                    // Tout désélectionner
                    selectedTransactions.removeAll()
                    transactionManager.selectedTransaction = nil
                    transactionManager.selectedTransactions = []
                    return nil
                }
                // Undo: Cmd+Z
                if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "z" {
                    ListTransactionsManager.shared.undo()
                    return nil
                }
                // Redo: Shift+Cmd+Z
                if event.modifierFlags.contains([.command, .shift]), event.charactersIgnoringModifiers == "Z" {
                    ListTransactionsManager.shared.redo()
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
    
    private func transactionByID(_ id: UUID) -> EntityTransaction? {
        return ListTransactionsManager.shared.listTransactions.first { $0.id == id }
    }
    
    private func toggleSelection() {
        let isCommand = NSEvent.modifierFlags.contains(.command)
        let isShift = NSEvent.modifierFlags.contains(.shift)
        
        if isShift, let lastID = transactionManager.lastSelectedTransactionID,
           let lastIndex = visibleTransactions.firstIndex(where: { $0.id == lastID }),
           let currentIndex = visibleTransactions.firstIndex(where: { $0.id == transaction.id }) {

            let range = lastIndex <= currentIndex
                ? lastIndex...currentIndex
                : currentIndex...lastIndex

            // Sélectionne tous les IDs dans la plage visible
            let idsInRange = visibleTransactions[range].map { $0.id }

            // Nettoie l’ancienne sélection et ajoute la nouvelle
            selectedTransactions.removeAll()
            selectedTransactions.formUnion(idsInRange)
            
        } else if isCommand {
            if selectedTransactions.contains(transaction.id) {
                selectedTransactions.remove(transaction.id)
            } else {
                selectedTransactions.insert(transaction.id)
            }
            // MAJ du dernier élément sélectionné, très important pour la sélection shift !
            transactionManager.lastSelectedTransactionID = transaction.id
        } else {
            selectedTransactions.removeAll()
            selectedTransactions.insert(transaction.id)
            // MAJ du dernier élément sélectionné, très important pour la sélection shift !
            transactionManager.lastSelectedTransactionID = transaction.id
        }

        if let firstSelectedId = selectedTransactions.first {
            transactionManager.selectedTransaction = ListTransactionsManager.shared.listTransactions.first { $0.id == firstSelectedId }
        }
        transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
        transactionManager.isCreationMode = false
    }
    
    private func supprimerTransactionsSelectionnees() {
        withAnimation {
            // 1) Capture les indices ordonnés des éléments sélectionnés dans la liste visible
            let selectedIDs = Array(selectedTransactions)
            let orderedSelectedIndices: [Int] = visibleTransactions.enumerated()
                .filter { selectedIDs.contains($0.element.id) }
                .map { $0.offset }
                .sorted()

            // 2) Déterminer une cible de re-sélection (index voisin)
            let targetIndexAfter: Int? = orderedSelectedIndices.last.map { $0 + 1 }
            let targetIndexBefore: Int? = orderedSelectedIndices.first.map { $0 - 1 }

            // 3) Supprimer du contexte si non déjà supprimé
            let transactionsToDelete = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            for transaction in transactionsToDelete where !transaction.isDeleted {
                ListTransactionsManager.shared.delete(entity: transaction)
            }

            // 4) Rafraîchir les données
            _ = ListTransactionsManager.shared.getAllData(ascending: false)

            // 5) Reconstituer la liste visible après suppression
            //    Ici, on part de visibleTransactions passé en paramètre de la vue. Si ta source change
            //    (filtre/tri), assure-toi que la vue parent le réévalue. On se contente de l'état courant.
            let newVisible = visibleTransactions

            // 6) Choisir une nouvelle sélection (l'élément après, sinon l'élément avant)
            var newSelectedID: UUID? = nil
            if let idx = targetIndexAfter, idx >= 0, idx < newVisible.count {
                newSelectedID = newVisible[idx].id
            } else if let idx = targetIndexBefore, idx >= 0, idx < newVisible.count {
                newSelectedID = newVisible[idx].id
            }

            // 7) Appliquer la nouvelle sélection et synchroniser le TransactionSelectionManager
            selectedTransactions.removeAll()
            if let id = newSelectedID {
                selectedTransactions.insert(id)
                transactionManager.selectedTransaction = ListTransactionsManager.shared.listTransactions.first { $0.id == id }
                transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            } else {
                transactionManager.selectedTransaction = nil
                transactionManager.selectedTransactions = []
            }
            transactionManager.isCreationMode = false
        }
    }
    private func mettreAJourRelevePourSelection(nouveauReleve: String) {
        withAnimation {
            guard let undo = ListTransactionsManager.shared.modelContext?.undoManager else {
                // Fallback sans undo manager
                let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
                for transaction in selected {
                    transaction.bankStatement = Double(nouveauReleve) ?? 0.0
                }
                
                return
            }

            undo.beginUndoGrouping()
            undo.setActionName("Change status")

            let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            for transaction in selected {
                transaction.bankStatement = Double(nouveauReleve) ?? 0.0
            }
            

            do {
                try ListTransactionsManager.shared.modelContext?.save()
            } catch {
                print("Error saving context after status change: \(error)")
            }
            undo.endUndoGrouping()
        }
    }

    private func mettreAJourStatusPourSelection(nouveauStatus: String) {
        withAnimation {
            guard let undo = ListTransactionsManager.shared.modelContext?.undoManager else {
                // Fallback sans undo manager
                let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
                if let status = StatusManager.shared.find(name: nouveauStatus) {
                    for transaction in selected {
                        transaction.status = status
                    }
                }
                return
            }

            undo.beginUndoGrouping()
            undo.setActionName("Change status")

            let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            if let status = StatusManager.shared.find(name: nouveauStatus) {
                for transaction in selected {
                    transaction.status = status
                }
            }

            do {
                try ListTransactionsManager.shared.modelContext?.save()
            } catch {
                print("Error saving context after status change: \(error)")
            }
            undo.endUndoGrouping()
        }
    }
    private func mettreAJourModePourSelection(nouveauMode: String) {
        withAnimation {
            guard let undo = ListTransactionsManager.shared.modelContext?.undoManager else {
                // Fallback sans undo manager
                let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
                if let mode = PaymentModeManager.shared.find(name: nouveauMode) {
                    for transaction in selected {
                        transaction.paymentMode = mode
                    }
                }
                return
            }

            undo.beginUndoGrouping()
            undo.setActionName("Change payment mode")

            let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            if let mode = PaymentModeManager.shared.find(name: nouveauMode) {
                for transaction in selected {
                    transaction.paymentMode = mode
                }
            }

            do {
                try ListTransactionsManager.shared.modelContext?.save()
            } catch {
                print("Error saving context after status change: \(error)")
            }
            undo.endUndoGrouping()
        }
    }
}




//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData

struct ListTransactions200: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var currentAccountManager : CurrentAccountManager
    @EnvironmentObject private var colorManager          : ColorManager
    
    var injectedTransactions: [EntityTransaction]? = nil
    private var transactions: [EntityTransaction] { injectedTransactions ?? ListTransactionsManager.shared.listTransactions }
    
    @Binding var dashboard: DashboardState
    @Binding var selectedTransactions: Set<UUID>
    @State private var information: AttributedString = ""
    
    @State private var refresh200 = false
    @State private var currentSectionIndex: Int = 0
    
    @State var soldeBanque = 0.0
    @State var soldeReel = 0.0
    @State var soldeFinal = 0.0
    
    // Clipboard state for copy/cut/paste
    @State private var clipboardTransactions: [EntityTransaction] = []
    @State private var isCutOperation = false
    
    // Récupère le compte courant de manière sécurisée.
    var compteCurrent: EntityAccount? {
        CurrentAccountManager.shared.getAccount()
    }
    
    var body: some View {
        VStack {
//            headerViewSection
//                .transaction { $0.animation = nil }
            summaryViewSection
            transactionListSection
        }

            .onChange(of: colorManager.colorChoix) { old, new in
            }
        
            .onReceive(NotificationCenter.default.publisher(for: .transactionsAddEdit)) { _ in
                printTag("transactionsAddEdit notification received")
                DispatchQueue.main.async {
                    _ = ListTransactionsManager.shared.getAllData()
                    SwiftUI.withTransaction(SwiftUI.Transaction(animation: nil)) {
 //                       refresh.toggle()
                    }
                    DispatchQueue.main.async {
                        applyDashboardFromBalances()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionsImported)) { _ in
                printTag("transactionsImported notification received")
                DispatchQueue.main.async {
                    _ = ListTransactionsManager.shared.getAllData()
                    SwiftUI.withTransaction(SwiftUI.Transaction(animation: nil)) {
//                        refresh.toggle()
                    }
                    DispatchQueue.main.async {
                        applyDashboardFromBalances()
                    }
                }
            }

            .onChange(of: currentAccountManager.currentAccountID) { old, new in
                printTag("Chgt de compte détecté: \(String(describing: new))")
                DispatchQueue.main.async {
                    _ = ListTransactionsManager.shared.getAllData()
                    SwiftUI.withTransaction(SwiftUI.Transaction(animation: nil)) {
//                        refresh200.toggle()
                    }
                    DispatchQueue.main.async {
                        applyDashboardFromBalances()
                    }
                }
            }
        
            .onChange(of: selectedTransactions) { _, _ in
                printTag("selectionDidChange called")
                selectionDidChange()
            }
        
            .onAppear() {
                balanceCalculation()
                DispatchQueue.main.async {
                    applyDashboardFromBalances()
                }
                selectionDidChange()
            }
        
        // Clipboard/copy/cut/paste handlers
            .onReceive(NotificationCenter.default.publisher(for: .copySelectedTransactions)) { _ in
                clipboardTransactions = transactions.filter { selectedTransactions.contains($0.id) }
                isCutOperation = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .cutSelectedTransactions)) { _ in
                clipboardTransactions = transactions.filter { selectedTransactions.contains($0.id) }
                isCutOperation = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .pasteSelectedTransactions)) { _ in
                if let targetAccount = CurrentAccountManager.shared.getAccount() {
                    
                    for transaction in clipboardTransactions {
                        
                        let status = StatusManager.shared.find(name : transaction.status!.name)
                        let paymentMode = PaymentModeManager.shared.find(name: transaction.paymentMode!.name)
                        
                        let newTransaction = EntityTransaction()
                        newTransaction.dateOperation = transaction.dateOperation
                        newTransaction.datePointage  = transaction.datePointage
                        newTransaction.status        = status
                        newTransaction.paymentMode   = paymentMode
                        newTransaction.checkNumber   = transaction.checkNumber
                        newTransaction.bankStatement = transaction.bankStatement
                        
                        newTransaction.account = targetAccount
                        
                        for item in transaction.sousOperations {
                            let sousOperation = EntitySousOperation()
                            
                            let category = CategoryManager.shared.find(name: item.category!.name)
                            
                            sousOperation.libelle     = item.libelle
                            sousOperation.amount      = item.amount
                            sousOperation.category    = category
                            sousOperation.transaction = newTransaction
                            
                            modelContext.insert(sousOperation)
                            newTransaction.addSubOperation(sousOperation)
                        }
                        
                        modelContext.insert(newTransaction)
                    }
                    if isCutOperation {
                        for transaction in clipboardTransactions {
                            modelContext.delete(transaction)
                        }
                    }
                    try? modelContext.save()
                    
                    _ = ListTransactionsManager.shared.getAllData()
                    clipboardTransactions = []
                    isCutOperation = false
                    SwiftUI.withTransaction(SwiftUI.Transaction(animation: nil)) {
 //                       refresh.toggle()
                    }
                    DispatchQueue.main.async {
                        applyDashboardFromBalances()
                    }
                }
            }
    }
    
    private var mainContent: some View {
        VStack {
            headerViewSection
                .transaction { $0.animation = nil }
            summaryViewSection
            transactionListSection
        }
    }
    
    private var summaryViewSection: some View {
        return SummaryView(
            dashboard: $dashboard
        )
            .frame(maxWidth: .infinity, maxHeight: 100)
    }
    
    private var headerViewSection: some View {
        HStack {
            Text("\(compteCurrent?.name ?? String(localized: "No checking account"))")
            Image(systemName: "info.circle")
                .foregroundColor(.accentColor)
            Text(information)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var transactionListSection: some View {
        NavigationView {
            GeometryReader { _ in
                List {
                    Section(header: EmptyView()) {
                        HStack(spacing: 0) {
                            columnGroup1()
                            columnGroup2()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    OperationRow(selectedTransactions: $selectedTransactions, transactions: transactions)
                }
                .transaction { $0.animation = nil }
                .listStyle(.plain)
                .frame(minWidth: 800, maxWidth: 1200)
            }
            .background(Color.white)
        }
    }
    @ViewBuilder
    func verticalDivider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 2, height: 20)
            .padding(.horizontal, 2)
    }
        
    @MainActor
    func resetDatabase(using context: ModelContext) {
        let transactions = ListTransactionsManager.shared.getAllData()
        
        for transaction in transactions {
            context.delete(transaction)
        }
        
        try? context.save()
//        loadTransactions()
        balanceCalculation()
    }
    
    private func columnGroup1() -> some View {
        HStack(spacing: 0) {
            Text("Date of pointing").bold().frame(width: ColumnWidths.datePointage, alignment: .leading)
            verticalDivider()
            Text("Date operation").bold().frame(width: ColumnWidths.dateOperation, alignment: .leading)
            verticalDivider()
            Text("Comment").bold().frame(width: ColumnWidths.libelle, alignment: .leading)
            verticalDivider()
            Text("Rubric").bold().frame(width: ColumnWidths.rubrique, alignment: .leading)
            verticalDivider()
            Text("Category").bold().frame(width: ColumnWidths.categorie, alignment: .leading)
            verticalDivider()
            Text("Amount").bold().frame(width: ColumnWidths.sousMontant, alignment: .leading)
            verticalDivider()
            Text("Bank Statement").bold().frame(width: ColumnWidths.releve, alignment: .leading)
            verticalDivider()
            Text("Check Number").bold().frame(width: ColumnWidths.cheque, alignment: .leading)
            verticalDivider()
        }
    }
    
    private func columnGroup2() -> some View {
        HStack(spacing: 0) {
            Text("Status").bold().frame(width: ColumnWidths.statut, alignment: .leading)
            verticalDivider()
            Text("Payment method").bold().frame(width: ColumnWidths.modePaiement, alignment: .leading)
            verticalDivider()
            Text("Amount").bold().frame(width: ColumnWidths.montant, alignment: .trailing)
        }
    }
    
    func selectionDidChange() {
        
        let selectedRow = selectedTransactions
        if selectedRow.isEmpty == false {
            
            var transactionsSelected = [EntityTransaction]()
            
            var solde = 0.0
            var expense = 0.0
            var income = 0.0
            
            let formatter = NumberFormatter()
            formatter.locale = Locale.current
            formatter.numberStyle = .currency
            
            // Filtrer les transactions correspondantes
            let selectedEntities = transactions.filter { selectedRow.contains($0.id) }
            
            for transaction in selectedEntities {
                transactionsSelected.append(transaction)
                let amount = transaction.amount
                
                solde += amount
                if amount < 0 {
                    expense += amount
                } else {
                    income += amount
                }
            }
            
            // Info
            let amountStr = formatter.string(from: solde as NSNumber)!
            let strExpense = formatter.string(from: expense as NSNumber)!
            let strIncome = formatter.string(from: income as NSNumber)!
            let count = selectedEntities.count
            
            let info = AttributedString(String(localized:"Selected \(count) transactions. "))
            
            var expenseAttr = AttributedString("Expenses: \(strExpense)")
            expenseAttr.foregroundColor = expense < 0 ? .red : .blue
            
            var incomeAttr = AttributedString(String(localized:", Incomes: \(strIncome)"))
            incomeAttr.foregroundColor = income < 0 ? .red : .blue
            
            let totalAttr = AttributedString(String(localized:", Total: \(amountStr)"))
            
            information = info + expenseAttr + incomeAttr + totalAttr
        }
    }
    
    private func balanceCalculation() {
        // Récupère les données de l'init
        
        guard let initCompte = InitAccountManager.shared.getAllData() else { return }
        
        // Initialisation des soldes
        var balanceRealise = initCompte.realise
        var balancePrevu   = initCompte.prevu
        var balanceEngage  = initCompte.engage
        let initialBalance = balancePrevu + balanceEngage + balanceRealise
        
        var computedSoldes: [(EntityTransaction, Double)] = []
        
        // Vérification des transactions disponibles
//        let transactions = ListTransactionsManager.shared.listTransactions
        let transactions = self.transactions
        
        let count = transactions.count
        
        // Calcul des soldes transaction par transaction
        for index in stride(from: count - 1, to: -1, by: -1) {
            let transaction = transactions[index]
            
            let status = transaction.status?.type ?? .inProgress
            
            // Mise à jour des soldes en fonction du status
            switch status {
            case .planned:
                balancePrevu += transaction.amount
            case .inProgress:
                balanceEngage += transaction.amount
            case .executed:
                balanceRealise += transaction.amount
            }
            
            // Calcul du solde de la transaction
            let soldeValue = (index == count - 1) ?
            (transaction.amount) + initialBalance :
            (transactions[index + 1].solde ?? 0.0) + (transaction.amount)
            computedSoldes.append((transaction, soldeValue))
        }
        
        let newSoldeBanque = balanceRealise
        let newSoldeReel   = balanceRealise + balanceEngage
        let newSoldeFinal  = balanceRealise + balanceEngage + balancePrevu

        DispatchQueue.main.async {
            // Applique les soldes calculés aux transactions
            for (transaction, solde) in computedSoldes {
                transaction.solde = solde
            }
            // Met à jour les états locaux
            self.soldeBanque = newSoldeBanque
            self.soldeReel   = newSoldeReel
            self.soldeFinal  = newSoldeFinal
            // Met à jour le dashboard
            applyDashboardFromBalances()
        }
        
        //    NotificationCenter.send(.updateBalance) // Décommente si nécessaire
    }
    
    private func applyDashboardFromBalances() {
        var tx = SwiftUI.Transaction()
        tx.disablesAnimations = true
        SwiftUI.withTransaction(tx) {
            dashboard.executed = soldeBanque
            dashboard.engaged  = soldeFinal
            dashboard.planned  = soldeReel
        }
    }
    
    private func groupTransactionsByYear(transactions: [EntityTransaction]) -> [YearGroup] {
        var groupedItems: [YearGroup] = []
        let calendar = Calendar.current
        
        // Group transactions by year
        let groupedByYear = Dictionary(grouping: transactions) { (transaction) -> Int in
            let components = calendar.dateComponents([.year], from: transaction.datePointage)
            return components.year ?? 0
        }
        
        for (year, yearTransactions) in groupedByYear {
            var yearGroup = YearGroup(year: year, monthGroups: [])
            
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


//
//  ListTransactions1.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 26/02/2025.
//

import SwiftUI
import SwiftData


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

//Statut de l'opération : Prévu, Engagé, Pointé. Vous pouvez utiliser le clavier pour choisir la valeur en tapant P pour Prévu, E pour Engagé et T pour Pointé.
// Lorsque le statut est Prévu ou Engagé, la date de pointage est estimée et le montant est modifiable.
// Lorsque le statut est Pointé, la date de pointage doit être celle indiquée sur le relevé et le montant n'est plus modifiable.

struct SummaryView: View {
    @Binding var dashboard: DashboardState
    
    var body: some View {
        HStack(spacing: 0) {
            
            VStack {
                Text("Final balance")
                Text(String(format: "%.2f €", dashboard.planned))
                    .font(.title)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

            VStack {
                Text("Actual balance")
                Text(String(format: "%.2f €", dashboard.engaged))
                    .font(.title)
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)
            
            VStack {
                Text("Bank balance")
                Text(String(format: "%.2f €", dashboard.executed))
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

        }
        .frame(maxWidth: .infinity)
    }
}

// Représente un regroupement par année.
struct TransactionsByYear100: Identifiable {
    let id = UUID()
    let year: String
    let months: [TransactionsByMonth100]
}

// Représente un groupe de transactions d'un mois précis (par exemple 2023-02).
struct TransactionsByMonth100: Identifiable {
    let id = UUID()
    let year: String
    let month: Int
    let transactions: [EntityTransaction]
    
    /// Formatage mois (ex: "Février")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR") // ou "en_US" etc.
        formatter.dateFormat = "LLLL" // nom du mois
        if let transaction = transactions.first {
            let date = transaction.datePointage
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

func groupTransactionsByYear(transactions: [EntityTransaction]) -> [TransactionsByYear100] {
    // Dictionnaire [year: [TransactionsByMonth]]
    var dictionaryByYear: [String: [TransactionsByMonth100]] = [:]

    // Dictionnaire [YearMonth : [EntityTransactions]]
    var yearMonthDict: [YearMonth: [EntityTransaction]] = [:]

    for transaction in transactions {
        guard let yearString = transaction.sectionYear else { continue }
        let datePointage = transaction.datePointage
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
        let sortedMonths = monthsArray.sorted { $0.month > $1.month }
        result.append(TransactionsByYear100(year: year, months: sortedMonths))
    }

    // Trier par année décroissante (ou croissante)
    return result.sorted { $0.year > $1.year }
}





//
//  ListTransactions2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 23/03/2025.
//

import SwiftUI
import SwiftData


struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private var transaction: EntityTransaction {
        ListTransactionsManager.shared.listTransactions[currentSectionIndex]
    }
    
    @State var currentSectionIndex: Int
    @Binding var selectedTransaction: Set<UUID>
    @State var refresh = false
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: { showPreviousSection() }) {
                    Text("◀️")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .disabled(currentSectionIndex == 0)
                
                Spacer()
                
                Button(action: { showNextSection() }) {
                    Text("▶️")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .disabled(currentSectionIndex >= ListTransactionsManager.shared.listTransactions.count - 1)
            }
            .padding()
            
            Text("Transaction Details")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            HStack {
                Text("Created at :")
                    .bold()
                Spacer()
                Text(Self.dateFormatter.string(from: transaction.createAt))
            }
            HStack {
                Text("Update at :")
                    .bold()
                Spacer()
                Text(Self.dateFormatter.string(from: transaction.updatedAt))
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
                Text(Self.dateFormatter.string(from: transaction.datePointage))
            }
            HStack {
                Text("Date operation :")
                    .bold()
                Spacer()
                Text(Self.dateFormatter.string(from: transaction.dateOperation))
            }
            HStack {
                Text("Payment method :")
                    .bold()
                Spacer()
                Text(transaction.paymentMode?.name ?? "—")
            }
            HStack {
                Text("Bank Statement :")
                    .bold()
                Spacer()
                Text(String(transaction.bankStatement))
            }
            
            HStack {
                Text("Status :")
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
                    //                    transactionManager.selectedTransaction = nil
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
        .onAppear {
            if let index = ListTransactionsManager.shared.listTransactions.firstIndex(where: { $0.id == selectedTransaction.first }) {
                currentSectionIndex = index
            }
        }
    }
    
    private func showPreviousSection() {
        guard currentSectionIndex > 0 else { return }
        currentSectionIndex -= 1
    }
    
    private func showNextSection() {
        guard currentSectionIndex < ListTransactionsManager.shared.listTransactions.count - 1 else { return }
        currentSectionIndex += 1
    }
}

//    .onAppear {
//        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
//            if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "a" {
//                // Tout sélectionner
//                for transaction in dataManager.listTransactions {
//                    selectedTransactions.insert(transaction.id)
//                }
//                transactionManager.selectedTransactions = dataManager.listTransactions
//                return nil
//            }
//            if event.keyCode == 53 { // Escape key
//                // Tout désélectionner
//                selectedTransactions.removeAll()
//                transactionManager.selectedTransaction = nil
//                transactionManager.selectedTransactions = []
//                return nil
//            }
//            return event
//        }
//    }
