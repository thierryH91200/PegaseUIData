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
        initManager.initializeLibrary(modelContext: modelContext)
        isInitialized = true // Marqueur pour indiquer la fin de l'initialisation
    }
}

struct ContentView100: View {
    
    @AppStorage("windowWidth")  var windowWidth: Double = 800
    @AppStorage("windowHeight")  var windowHeight: Double = 600
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selection1: UUID?
    @State private var selection2: String? = "Liste des transactions"
    @State private var isVisible: Bool = true
    @State private var isToggle: Bool = false

    @State private var entityAccount: [EntityAccount] = []    
    @State private var inspectorIsShown: Bool = false
    
    init() {
    }
    
    var body: some View {
        HStack
        {
            NavigationSplitView {
                SidebarContainer(selection1: $selection1, selection2: $selection2)
            }
            content :
            {
                Text("Content")
                DetailContainer(selection2: $selection2, isVisible: $isVisible)
            }
            detail :
            {
                if isVisible
                {
                    OperationView(modeCreation: false)
                        .frame(width: 250, height: 600, alignment: .trailing)
                        .alignmentGuide(.trailing) { _ in 0 }
                }
            }
            .frame(minWidth: 800, maxWidth: .infinity) // Définit les contraintes globales du NavigationSplitView
            .navigationSplitViewStyle(.balanced) // Style équilibré pour ajuster les tailles

            .onAppear {
                initManager.initializeLibrary(modelContext: modelContext)
                entityAccount = AccountManager.shared.getRoot(modelContext: modelContext)
                AccountManager.shared.printAccount(entityAccount: entityAccount.first!, description: "Account")
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
                    Label("Apparence", systemImage: "paintbrush")
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
                        Label("United", systemImage: "paintbrush.fill")
                    }
                    Button(action: { chooseCouleur("Income/Expense") }) {
                        Label("Income/Expense", systemImage: "dollarsign.circle")
                    }
                    Button(action: { chooseCouleur("Rubric") }) {
                        Label("Rubric", systemImage: "tag.fill")
                    }
                    Button(action: { chooseCouleur("Payment Mode") }) {
                        Label("Payment mode", systemImage: "creditcard.fill")
                    }
                    Button(action: { chooseCouleur("Statut") }) {
                        Label("Statut", systemImage: "checkmark.circle.fill")
                    }
                } label: {
                    Label("Choose the color", systemImage: "paintpalette")
                }
            }
        }
    }

    private func saveWindowSize(width: CGFloat, height: CGFloat) {
        windowWidth = width
        windowHeight = height
    }

}

// Fonction d'action pour chaque choix de couleur
private func chooseCouleur(_ type: String) {
    // Ajoutez ici la logique de gestion du choix de couleur
    print("Couleur sélectionnée : \(type)")
}

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
            Sidebar1A(selection1: $selection1)
            Divider()
            Sidebar2A(selection2: $selection2)
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
    }
}

struct DetailContainer: View {
    @Binding var selection2: String?
    @Binding var isVisible: Bool

    let detailViews: [String: (Binding<Bool>) -> AnyView] = [
        "Liste des transactions" : { isVisible in AnyView(ListTransactions(isVisible           : isVisible)) },
        "Courbe de trésorerie"   : { isVisible in AnyView(TreasuryCurveView(isVisible          : isVisible)) },
        "Site Web de la banque"  : { isVisible in AnyView(BankWebsiteView(isVisible            : isVisible)) },
        "Rapprochement internet" : { isVisible in AnyView(InternetReconciliationView(isVisible : isVisible)) },
        "Relevé bancaire"        : { isVisible in AnyView(BankStatementView(isVisible          : isVisible)) },
        "Notes"                  : { isVisible in AnyView(NotesView(isVisible                  : isVisible)) },

        // Rapport
        "Categorie Bar1"         : { isVisible in AnyView(CategorieBar1View(isVisible         : isVisible)) },
        "Categorie Bar2"         : { isVisible in AnyView(CategorieBar2View(isVisible         : isVisible)) },
        "Mode de paiement"       : { isVisible in AnyView(ModePaiementView(isVisible          : isVisible)) },
        "Recette Depense Bar"    : { isVisible in AnyView(RecetteDepenseBarView(isVisible     : isVisible)) },
        "Recette Depense Pie"    : { isVisible in AnyView(RecetteDepensePieView(isVisible     : isVisible)) },
        "Rubrique Bar"           : { isVisible in AnyView(RubriqueBarView(isVisible           : isVisible)) },
        "Rubrique Pie"           : { isVisible in AnyView(RubriquePieView(isVisible           : isVisible)) },

        // Reglage
        "Identité"               : {  isVisible in AnyView(Identy(isVisible                   : isVisible)) },
        "Echeancier"             : {  isVisible in AnyView(SchedulerView(isVisible            : isVisible)) },
        "Réglage"                : {  isVisible in AnyView(SettingView(isVisible              : isVisible)) }
    ]

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

//struct SidebarDialogView: View {
//    var body: some View {
//        Spacer(minLength: 10)
//        OperationView(modeCreation: false)
//            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
//        Spacer(minLength: 10)
//    }
//}
//

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


