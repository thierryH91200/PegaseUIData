////
////  Untitled 2.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 25/03/2025.
////
//
//import SwiftUI
//import SwiftData
//
//struct ListTransactionsView100: View {
//    
//    @Environment(\.modelContext) private var modelContext
//    
//    @State private var selectedTransactions: Set<UUID> = []
//    @State private var refreshTick: Int = 0
//
//    @Binding var dashboard: DashboardState
//    var injectedTransactions: [EntityTransaction]? = nil
//
//    private var transactions: [EntityTransaction] { injectedTransactions ?? ListTransactionsManager.shared.listTransactions }
//
//    var body: some View {
//        
//        VStack(spacing: 0) {
//                        
//            #if DEBUG
//                        Button("Load demo data") {
//                            loadDemoData()
//                        }
//                        .textCase(.lowercase) // empêche SwiftUI de mettre en majuscules
//                        .padding(.bottom)
//            #endif
//            
//            Divider()
//            ListTransactions200(
//                injectedTransactions: injectedTransactions,
//                dashboard: $dashboard,
//                selectedTransactions: $selectedTransactions
//            )
//            .transaction { $0.animation = nil }
//            .id(refreshTick)
//            .padding()
//            
//            .task {
//                await performFalseTask()
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .loadDemoRequested)) { _ in
//                loadDemoData()
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .resetDatabaseRequested)) { _ in
//                resetDatabase()
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .transactionsAddEdit)) { _ in
//                printTag("transactionsAddEdit notification received")
//                DispatchQueue.main.async {
//                    _ = ListTransactionsManager.shared.getAllData()
//                    withAnimation(nil) {
//                        selectedTransactions.removeAll()
//                    }
//                    updateSummary()
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .transactionsImported)) { _ in
//                printTag("transactionsImported notification received")
//                DispatchQueue.main.async {
//                    _ = ListTransactionsManager.shared.getAllData()
//                    SwiftUI.withTransaction(.init(animation: nil)) {
//                        selectedTransactions.removeAll()
//                    }
//                    updateSummary()
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .transactionsSelectionChanged)) { _ in
//                updateSummary()
//                SwiftUI.withTransaction(.init(animation: nil)) {
//                    refreshTick &+= 1
//                }
//            }
//
//            .onReceive(NotificationCenter.default.publisher(for: .treasuryListNeedsRefresh)) { _ in
//                DispatchQueue.main.async {
//                    updateSummary()
//                }
//            }
//            .onChange(of: injectedTransactions ?? []) { _, _ in
//                DispatchQueue.main.async {
//                    updateSummary()
//                }
//            }
//            .onAppear {
//                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
//                    guard event.modifierFlags.contains(.command), let characters = event.charactersIgnoringModifiers else {
//                        return event
//                    }
//                    
//                    switch characters {
//                    case "c":
//                        NotificationCenter.default.post(name: .copySelectedTransactions, object: nil)
//                        return nil
//                    case "x":
//                        NotificationCenter.default.post(name: .cutSelectedTransactions, object: nil)
//                        return nil
//                    case "v":
//                        NotificationCenter.default.post(name: .pasteSelectedTransactions, object: nil)
//                        return nil
//                    default:
//                        return event
//                    }
//                }
//            }
//            .onAppear {
//                DispatchQueue.main.async {
//                    DispatchQueue.main.async {
//                        updateSummary()
//                    }
//                }
//            }
//        }
//    }
//    
//    private func updateSummary() {
//        // Calcule d'abord les valeurs
//        let newExecuted = calculateExecuted()
//        let newEngaged  = newExecuted + calculateEngaged()
//        let newPlanned  = newEngaged  + calculatePlanned()
//
//        // No-op si identiques (évite des commits inutiles)
//        if dashboard.executed == newExecuted &&
//           dashboard.engaged  == newEngaged  &&
//           dashboard.planned  == newPlanned {
//            return
//        }
//
//        // Ecritures coalisées et sans animation
//        var tx = SwiftUI.Transaction()
//        tx.disablesAnimations = true
//        SwiftUI.withTransaction(tx) {
//            dashboard.executed = newExecuted
//            dashboard.engaged  = newEngaged
//            dashboard.planned  = newPlanned
//        }
//    }
//    
//    @MainActor
//    func resetDatabase() {
//        let transactions = ListTransactionsManager.shared.getAllData()
//        
//        for transaction in transactions {
//            modelContext.delete(transaction)
//        }
//        try? modelContext.save()
//    }
//    
//    private func performFalseTask() async {
//        // Exécuter une tâche asynchrone (par exemple, un délai)
//        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
//        await MainActor.run {
//            dashboard.isVisible = true
//        }
//    }
//    
//    @MainActor
//    func loadDemoData() {
//        let demoTransactions: [(String, Double, Int)] = [
//            ("Achat supermarché", -45.60, 2),
//            ("Salaire", 2000.00, 0),
//            ("Facture électricité", -120.75, 1),
//            ("Virement reçu", 350.00, 2),
//            ("Abonnement streaming", -12.99, 1)
//        ]
//    }
//    
//    func calculatePlanned() -> Double {
//        transactions
//            .filter { $0.status?.type == .planned }
//            .map(\.amount)
//            .reduce(0, +)
//    }
//    
//    func calculateEngaged() -> Double {
//        transactions
//            .filter { $0.status?.type == .inProgress }
//            .map(\.amount)
//            .reduce(0, +)
//    }
//    
//    func calculateExecuted() -> Double {
//        transactions
//            .filter { $0.status?.type == .executed  }
//            .map(\.amount)
//            .reduce(0, +)
//    }
//}
//
//
//struct YearGroup {
//    var year: Int
//    var monthGroups: [MonthGroup]
//}
//
//struct MonthGroup {
//    var month: String
//    var transactions: [EntityTransaction]
//}
//
//// Exemple d'extension pour formater les dates
//extension Date {
//    func formatted() -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .none
//        return formatter.string(from: self)
//    }
//}
//
//func formatPrice(_ amount: Double) -> String {
//    let formatter = NumberFormatter()
//    formatter.numberStyle = .currency // format monétaire
//    formatter.locale = Locale.current // devise de l'utilisateur
//    let format = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
//    return format
//}
//
//
//struct PriceText: View {
//    let amount: Double
//
//    var body: some View {
//        Text(amount, format: .currency(code: currencyCode))
//    }
//
//    private var currencyCode: String {
//        Locale.current.currency?.identifier ?? "EUR"
//    }
//}
//
//func cleanDouble(from string: String) -> Double {
//    // Supprime les caractères non numériques sauf , et .
//    let cleanedString = string.filter { "0123456789,.".contains($0) }
//    
//    // Convertir la virgule en point si nécessaire
//    let normalized = cleanedString.replacingOccurrences(of: ",", with: ".")
//    
//    return Double(normalized) ?? 0.0
//}
//
//// Keyboard shortcut notifications
//extension Notification.Name {
//    static let copySelectedTransactions = Notification.Name("copySelectedTransactions")
//    static let cutSelectedTransactions = Notification.Name("cutSelectedTransactions")
//    static let pasteSelectedTransactions = Notification.Name("pasteSelectedTransactions")
//    static let transactionsSelectionChanged = Notification.Name("transactionsSelectionChanged")
//    static let treasuryListNeedsRefresh = Notification.Name("treasuryListNeedsRefresh")
//}
//
