//
//  Content.swift
//  PegaseUI
//
//  Created by Thierry hentic on 27/10/2024.
//

import SwiftUI
import AppKit
import SwiftData

class ContentViewModel: ObservableObject {
    @Published var isInitialized = false

    init(modelContext: ModelContext) {
        InitManager.shared.configure(with: modelContext)
        InitManager.shared.initialize()
        isInitialized = true // Marqueur pour indiquer la fin de l'initialisation
    }
}

class ColorManager: ObservableObject {
    
    @Published var selectedColorType: String = "Payment Mode"
    
    func printColors() {
        print("ColorManager : ", selectedColorType)
    }

    func colorForTransaction(_ transaction: EntityTransactions) -> Color {
        switch selectedColorType {
        case "United":
            return .black
        case "Income/Expense":
            return transaction.amount >= 0 ? .green : .red
        case "Rubric":
            return Color(transaction.sousOperations.first?.category?.rubric?.color ?? .black)
        case "Payment Mode":
            return Color(transaction.paymentMode?.color ?? .black)
        case "Status":
            return Color(transaction.status?.color ?? .gray)
        default:
            return .black
        }
    }
}

class TransactionSelectionManager: ObservableObject {
    @Published var selectedTransaction: EntityTransactions?
    @Published var isCreationMode: Bool = true
}

struct ContentView100: View {
    
    @AppStorage("windowWidth")  var windowWidth: Double = 800
    @AppStorage("windowHeight")  var windowHeight: Double = 600
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var transactionManager = TransactionSelectionManager()
    @StateObject private var colorManager = ColorManager()
    @StateObject private var listDataManager = ListDataManager()

    @State private var selectedTransaction: EntityTransactions?
    @State private var isCreationMode : Bool = true

    var transactions: [EntityTransactions] = [] // Liste des transactions

    @State private var selection1: UUID?
    @State private var selection2: String? = "Notes"
    @State private var isVisible: Bool = true
    @State private var isToggle: Bool = false

    @State private var entityAccount: [EntityAccount] = []    
    @State private var inspectorIsShown: Bool = false
    
    @State private var selectedColor: String? = "United"
      
    var body: some View {
        HStack
        {
            NavigationSplitView {
                SidebarContainer(selection1: $selection1, selection2: $selection2)
                    .navigationSplitViewColumnWidth(min: 256, ideal: 256, max: 400)

            }
            content :
            {
                DetailContainer(selection2: $selection2, isVisible: $isVisible, selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
                    .navigationSplitViewColumnWidth( min: 150, ideal: 800)
            }
            detail :
            {
                if isVisible
                {
                    OperationDialog()
                }
            }
            .environmentObject(transactionManager)     // Injection de l’EnvironmentObject
            .environmentObject(listDataManager)        // Injection de l’EnvironmentObject
            .navigationSplitViewStyle(.balanced)

            .onAppear {
//                InitManager.shared.configure(with: modelContext)
//                InitManager.shared.initialize()
//                let entityAccount = AccountManager.shared.getRoot(modelContext: modelContext)
//                AccountManager.shared.printAccount(entityAccount: entityAccount.first!, description: "Account")
            }
            
            Spacer(minLength: 10)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    print("Nouvel élément ajouté")
                }) {
                    Label("Add", systemImage: "plus")
                }
            }
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    inspectorIsShown.toggle()
                } label: {
                    Label("Show inspector", systemImage: "sidebar.right")
                }
                Menu {
                    Button("Light") { setAppearance(.aqua) }
                    Button("Dark") { setAppearance(.darkAqua) }
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                Menu {
                    Button(action: { changeSearchFieldItem("All") }) { Text("All") }
                    Button(action: { changeSearchFieldItem("Comment") }) { Text("Comment") }
                    Button(action: { changeSearchFieldItem("Category") }) { Text("Category") }
                    Button(action: { changeSearchFieldItem("Rubric") }) { Text("Rubric") }
                } label: {
                    Label("Find", systemImage: "magnifyingglass")
                }
                
                Button(action: {
                    print("Paramètres ouverts")
                }) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Menu {
                    Button(action: { chooseCouleur("United") }) {
                        HStack {
                            Label("United", systemImage: "paintbrush.fill")
                            if selectedColor == "United" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Button(action: { chooseCouleur("Income/Expense") }) {
                        Label("Income/Expense", systemImage: "dollarsign.circle")
                        if selectedColor == "Income/Expense" {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button(action: { chooseCouleur("Rubric") }) {
                        Label("Rubric", systemImage: "tag.fill")
                        if selectedColor == "Rubric" {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button(action: { chooseCouleur("Payment Mode") }) {
                        Label("Payment method", systemImage: "creditcard.fill")
                        if selectedColor == "Payment Mode" {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button(action: { chooseCouleur("Status") }) {
                        HStack {
                            Label("Status", systemImage: "checkmark.circle.fill")
                            if selectedColor == "Status" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    Label("Choose the color", systemImage: "paintpalette")
                }
                if isVisible == false{
//                    ListTransactions(isVisible: $isVisible, selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)
//                        .environmentObject(colorManager)
                }
            }
        }
        .environmentObject(colorManager)  // Injection de ColorManager pour toutes les sous-vues
    }

    private func chooseCouleur(_ color: String) {
        colorManager.selectedColorType = color
        selectedColor = color
//        isVisible = false // Modifie l'état pour rafraîchir l'UI
    }

    private func saveWindowSize(width: CGFloat, height: CGFloat) {
        windowWidth = width
        windowHeight = height
    }
}

// Fonction d'action pour chaque choix de couleur

private func changeSearchFieldItem(_ itemType: String) {
    // Ajoutez ici la logique pour gérer la sélection du champ de recherche
    print("Champ de recherche sélectionné : \(itemType)")
}

private func setAppearance(_ appearance: NSAppearance.Name) {
    NSApp.appearance = NSAppearance(named: appearance)

    // Pour s'assurer que la fenêtre actuelle est également mise à jour
    if let window = NSApplication.shared.windows.first {
        window.appearance = NSAppearance(named: appearance)
    }
}

struct SidebarContainer: View {
    @Binding var selection1: UUID?
    @Binding var selection2: String?

    var body: some View {
        VStack(spacing: 0) {
            Sidebar1A()
            Divider()
            Sidebar2A(selection2: $selection2)
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
}

struct DetailContainer: View {
    @Binding var selection2: String?
    @Binding var isVisible: Bool
    @Binding var selectedTransaction: EntityTransactions?
    @Binding var isCreationMode: Bool

    var detailViews: [String: (Binding<Bool>) -> AnyView] {
        [
            String(localized: "List of Transactions",table: "Menu")     : { isVisible in AnyView(ListTransactionsView(isVisible       : isVisible)) },
            //selectedTransaction: $selectedTransaction, isCreationMode: $isCreationMode)) },
            String(localized: "Cash Flow Curve",table: "Menu")          : { isVisible in AnyView(TreasuryCurveView(isVisible          : isVisible)) },
            String(localized: "Bank website",table: "Menu")             : { isVisible in AnyView(BankWebsiteView(isVisible            : isVisible)) },
            String(localized: "Internet rapprochement",table: "Menu")   : { isVisible in AnyView(InternetReconciliationView(isVisible : isVisible)) },
            String(localized: "Bank Statement",table: "Menu")           : { isVisible in AnyView(BankStatementView(isVisible          : isVisible)) },
            String(localized: "Notes",table: "Menu")                    : { isVisible in AnyView(NotesView(isVisible                  : isVisible)) },
            
            // Rapport
            String(localized: "Category Bar1",table: "Menu")            : { isVisible in AnyView(CategorieBar1View(isVisible         : isVisible)) },
            String(localized: "Category Bar2",table: "Menu")            : { isVisible in AnyView(CategorieBar2View(isVisible         : isVisible)) },
            String(localized: "Payment method" ,table: "Menu")          : { isVisible in AnyView(ModePaiementBarView(isVisible       : isVisible)) },
            String(localized: "Recipe / Expense Bar",table: "Menu")     : { isVisible in AnyView(RecetteDepenseBarView(isVisible     : isVisible)) },
            String(localized: "Recipe / Expense Pie",table: "Menu")     : { isVisible in AnyView(RecetteDepensePieView(isVisible     : isVisible)) },
            String(localized: "Rubric Bar",table: "Menu")               : { isVisible in AnyView(RubriqueBarView(isVisible           : isVisible)) },
            String(localized: "Rubric Pie" ,table: "Menu")              : { isVisible in AnyView(RubriquePieView(isVisible           : isVisible)) },
            
            // Reglage
            String(localized: "Identity",table: "Menu")                 : {  isVisible in AnyView(Identy(isVisible                   : isVisible)) },
            String(localized: "Scheduler",table: "Menu" )               : {  isVisible in AnyView(SchedulerView(isVisible            : isVisible)) },
            String(localized: "Settings",table: "Menu" )                : {  isVisible in AnyView(SettingView(isVisible              : isVisible))
            }
        ]
    }
    
    
    var body: some View {
        VStack {
            if let detailView = localizedDetailView(for: selection2) {
                detailView($isVisible)
            } else {
                Text("Content pour Sidebar 2 \(selection2 ?? "")")
            }
        }
    }

    func localizedDetailView(for selection: String?) -> ((Binding<Bool>) -> AnyView)? {
        guard let selection = selection else { return nil }
        return detailViews[selection]
    }
}

struct Sidebar2A: View {

    @Binding var selection2: String?

    var body: some View {

        let datas = Bundle.main.decode([Datas].self, from: "Feeds.plist" )

        List(selection: $selection2) {
            ForEach(datas) { section in
                Section(section.name) {
                    ForEach(section.children) { child in
                        Label(child.name, systemImage: child.icon).tag(child.name)
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .navigationTitle("Display")
        .listStyle(SidebarListStyle())
        .frame(maxHeight: .infinity) // Prend toute la place disponible
    }
}


