//
//  Content.swift
//  PegaseUI
//
//  Created by Thierry hentic on 27/10/2024.
//

import SwiftUI
import Foundation
import AppKit
import SwiftData

struct ContentView100: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selection1: String? = "John"
    @State private var selection2: String? = localizeString("Liste des transactions")
    @State private var isVisible: Bool = true
    //    @State private var isToggle: Bool = true
    
    
    @State private var inspectorIsShown: Bool = false
    
//    init() {
//       initializeLibrary(modelContext: modelContext)
//
//    }
    
    var body: some View {
        HStack
        {
            NavigationSplitView {
                Text("SideBar")
//                SidebarContainer(selection1: $selection1, selection2: $selection2)
            }
            content :
            {
                Text("Content")
//                DetailContainer(selection2: $selection2, isVisible: $isVisible)
            }
            detail :
            {
                if isVisible
                {
                    OperationView(modeCreation: false)
                        .frame(width: 350, height: 600, alignment: .trailing)
                        .alignmentGuide(.trailing) { _ in 0 }
                }
            }
            .onAppear {
                initializeLibrary(modelContext: modelContext)
            }
            .alignmentGuide(.trailing) { _ in isVisible ? 200 : 0 }
            Spacer(minLength: 10)
        }

    }
    
    func initializeLibrary(modelContext: ModelContext) /*async*/ {
        
        let entities = AccountManager.shared.getRoot(modelContext: modelContext)
        if entities.isEmpty == true {
            /*await*/ setupForNilLibrary(modelContext: modelContext)
        }
    }
    
    func setupForNilLibrary(modelContext: ModelContext) /*async*/ {
        // Création de l'élément racine
        let root = AccountFactory.createAccount(modelContext: modelContext, name: "Root", icon: "", idName: "", idPrenom: "", numAccount: "", type: 0)
        root.isRoot = true
        modelContext.insert(root)
        
        // Création des comptes
        let header1 = AccountFactory.createHeader(modelContext: modelContext, name: "BankAccount", parent: root)
        let header2 = AccountFactory.createHeader(modelContext: modelContext, name: "BankAccount", parent: root)
        
        let accountsConfig: [(name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int)] = [
            ("Current_account", "icons8-museum-80", "Localizations.Document.Martin", "Pierre", "00045700E", 0),
            ("Current_account", "icons8-museum-80", "Martin", "Marie", "00045701F", 0),
            ("Carte_de_crédit", "discount", "Martin", "Pierre", "00045702G", 1),
            ("Document.Save", "icons8-money-box-80", "Durand", "Jean", "00045703H", 2),
            ("Current_account", "icons8-museum-80", "Durand", "Jean", "00045704J", 0)
        ]
        
        for config in accountsConfig.prefix(4) {
            let account = AccountFactory.createAccount(
                modelContext: modelContext, name: config.name,
                icon: config.icon,
                idName: config.idName,
                idPrenom: config.idPrenom,
                numAccount: config.numAccount,
                type: config.type
            )
            header1.addChild(account)
        }
        
        for config in accountsConfig[4...4] {
            let account = AccountFactory.createAccount(
                modelContext: modelContext,
                name: config.name,
                icon: config.icon,
                idName: config.idName,
                idPrenom: config.idPrenom,
                numAccount: config.numAccount,
                type: config.type
            )
            header2.addChild(account)
        }
        
        // Enregistrement des modifications
        saveContext(modelContext)
        
//        do {
//            try await Task.sleep(nanoseconds: 1_000_000_000) // Simule une pause de 1 seconde
//            print("Configuration effectuée")
//        } catch {
//            print("La tâche a été annulée : \(error)")
//        }
    }
    
    func saveContext(_ modelContext: ModelContext) {
        let path = getSQLiteFilePath()
        print(path!)
        do {
            try modelContext.save()
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct AccountFactory {
    static func createAccount(modelContext: ModelContext, name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
        let account = EntityAccount()
        account.name = name
        account.nameImage = icon
        account.identity = EntityIdentity(name: idName, surName: idPrenom) // Assurez-vous que `EntityIdentity` existe avec un init dédié
        
        let initAccount = EntityInitAccount()
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount
        
        account.type = type
        account.uuid = UUID()
        
        modelContext.insert(account)
        return account
    }
    
    static func createHeader(modelContext: ModelContext , name: String, parent: EntityAccount) -> EntityAccount {
        let header = EntityAccount()
        header.isHeader = true
        header.name = name
        header.uuid = UUID()
        header.parent = parent
        
        modelContext.insert(header)
        return header
    }
}

func getSQLiteFilePath() -> String? {
    guard let _ = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return nil}

    
    if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let path = "Core Data SQLite file is located at: \(url.path)"
        return path
    }
    return nil
}




//            NavigationSplitView {
//                SidebarContainer(selection1: $selection1, selection2: $selection2)
//            }
//            content :
//            {
//                DetailContainer(selection2: $selection2, isVisible: $isVisible)
//            }
//            detail :
//            {
//                if isVisible
//                {
//                    OperationView(modeCreation: false)
//                        .frame(width: 350, height: 600, alignment: .trailing)
//                        .alignmentGuide(.trailing) { _ in 0 }
//                }
//            }
//            .alignmentGuide(.trailing) { _ in isVisible ? 200 : 0 }
//            Spacer(minLength: 10)

//        }
//        .toolbar {
//            ToolbarItemGroup(placement: .navigation) {
//                Button(action: {
//                    print("Nouvel élément ajouté")
//                }) {
//                    Label("Ajouter", systemImage: "plus")
//                }
//            }

//            ToolbarItemGroup(placement: .automatic) {
//                Button {
//                    inspectorIsShown.toggle()
//                } label: {
//                    Label("Show inspector", systemImage: "sidebar.right")
//                }
//
//                Menu {
//                    Button("Light") { setAppearance(.aqua) }
//                    Button("Dark") { setAppearance(.darkAqua) }
//                } label: {
//                    Label("Apparence", systemImage: "paintbrush")
//                }
//
//                Menu {
//                    Button(action: { changeSearchFieldItem("all") }) { Text("all") }
//                    Button(action: { changeSearchFieldItem("comment") }) { Text("comment") }
//                    Button(action: { changeSearchFieldItem("category") }) { Text("category") }
//                    Button(action: { changeSearchFieldItem("rubric") }) { Text("rubric") }
//                } label: {
//                    Label("Recherche", systemImage: "magnifyingglass")
//                }
//            }
////
//            ToolbarItemGroup(placement: .automatic) {
//                Menu {
//                    Button(action: { chooseCouleur("Unie") }) {
//                        Label("Unie", systemImage: "paintbrush.fill")
//                    }
//                    Button(action: { chooseCouleur("Income/Expense") }) {
//                        Label("Income/Expense", systemImage: "dollarsign.circle")
//                    }
//                    Button(action: { chooseCouleur("Rubric") }) {
//                        Label("Rubric", systemImage: "tag.fill")
//                    }
//                    Button(action: { chooseCouleur("Payment Mode") }) {
//                        Label("Payment Mode", systemImage: "creditcard.fill")
//                    }
//                    Button(action: { chooseCouleur("Statut") }) {
//                        Label("Statut", systemImage: "checkmark.circle.fill")
//                    }
//                } label: {
//                    Label("Choisir Couleur", systemImage: "paintpalette")
//                }
//
//                Button(action: {
//                    print("Paramètres ouverts")
//                }) {
//                    Label("Paramètres", systemImage: "gear")
//                }

//                Toggle(isOn: $isToggle) {
//                    Image(systemName: "sidebar.trailing")
//                }
//                .toggleStyle(.button)
//                .keyboardShortcut("r", modifiers: .command)
////            }
//        }
//    }
//

//    private func initializeLibrary(modelContext: ModelContext) {
//        //            modelContext = modelContext
//        let entities = AccountManager.shared.getRoot(modelContext: modelContext)
//
//        if entities.isEmpty == true {
//            self.setupForNilLibrary()
//        }
//    }
//
//    private func setupForNilLibrary() {
//        // Création de l'élément racine
//        let root = EntityAccount()
//        root.isRoot = true
//        root.name = "Root"
//        root.uuid = UUID()
//
//        // Création des comptes
//        let pierreAccount = createAccount(
//            name: "Current_account",
//            icon: "icons8-museum-80",
//            idName: "Localizations.Document.IdName",
//            idPrenom: "Localizations.Document.IdPrenom",
//            numAccount: "00045700E",
//            type: 0
//        )
//
//        let marieAccount = createAccount(
//            name: "Current_account",
//            icon: "icons8-museum-80",
//            idName: "Martin",
//            idPrenom: "Marie",
//            numAccount: "00045701F",
//            type: 0
//        )
//
//        let carteDeCredit1 = createAccount(
//            name: "Carte_de_crédit",
//            icon: "discount",
//            idName: "Martin",
//            idPrenom: "Pierre",
//            numAccount: "00045702G",
//            type: 1
//        )
//
//        let saving = createAccount(
//            name: "Document.Save",
//            icon: "icons8-money-box-80",
//            idName: "Durand",
//            idPrenom: "Jean",
//            numAccount: "00045703H",
//            type: 2
//        )
//
//        let jeanAccount = createAccount(
//            name: "Current_account",
//            icon: "icons8-museum-80",
//            idName: "Durand",
//            idPrenom: "Jean",
//            numAccount: "00045704J",
//            type: 0
//        )
//
//        // Création des en-têtes
//        let header1 = createHeader(name: "BankAccount", parent: root)
//        let header2 = createHeader(name: "BankAccount", parent: root)
//
//        // Ajout des comptes aux en-têtes
//        header1.children?.append(pierreAccount)
//        header1.children?.append(marieAccount)
//        header1.children?.append(carteDeCredit1)
//        header1.children?.append(saving)
//
//        header2.children?.append(jeanAccount)
//
//        // Enregistrement des modifications
//        do {
//            try modelContext.save()
//        } catch {
//            print("Erreur lors de la sauvegarde : \(error)")
//        }
//    }
//
//    private func createAccount(name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
//
//        let account = EntityAccount()
//        account.name = name
//        account.nameImage = icon
//        account .identity?.name = idName
//        account.identity?.surName = idPrenom
//
//        let initAccount = EntityInitAccount()
//        initAccount.codeAccount = numAccount
//        initAccount.account = account
//        account.initAccount = initAccount
//
//        account.type = type
//        account.uuid = UUID()
//        return account
//    }
//
//    private func createHeader(name: String, parent: EntityAccount) -> EntityAccount {
//        let header = EntityAccount()
//        header.isHeader = true
//        header.name = name
//        header.uuid = UUID()
//        header.parent = parent
//        return header
//    }
//}
//
//// Fonction d'action pour chaque choix de couleur
//private func chooseCouleur(_ type: String) {
//    // Ajoutez ici la logique de gestion du choix de couleur
//    print("Couleur sélectionnée : \(type)")
//}
//
//private func changeSearchFieldItem(_ itemType: String) {
//    // Ajoutez ici la logique pour gérer la sélection du champ de recherche
//    print("Champ de recherche sélectionné : \(itemType)")
//}
//
//private func setAppearance(_ appearance: NSAppearance.Name) {
//    NSApp.appearance = NSAppearance(named: appearance)
//
//    // Pour s'assurer que la fenêtre actuelle est également mise à jour
//    if let window = NSApplication.shared.windows.first {
//        window.appearance = NSAppearance(named: appearance)
//    }
//}
//
//
//
//struct SidebarContainer: View {
//    @Binding var selection1: String?
//    @Binding var selection2: String?
//
//    var body: some View {
//        VStack(spacing: 0) {
//            Sidebar1A(selection1: $selection1)
//            Divider()
//            Sidebar2A(selection2: $selection2)
//        }
//        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
//    }
//}
//
//struct DetailContainer: View {
//    @Binding var selection2: String?
//    @Binding var isVisible: Bool
//
//    let detailViews: [String: (Binding<Bool>) -> AnyView] = [
//        "Liste des transactions" : { isVisible in AnyView(ListTransactions(isVisible           : isVisible)) },
//        "Courbe de trésorerie"   : { isVisible in AnyView(TreasuryCurveView(isVisible          : isVisible)) },
//        "Site Web de la banque"  : { isVisible in AnyView(BankWebsiteView(isVisible            : isVisible)) },
//        "Rapprochement internet" : { isVisible in AnyView(InternetReconciliationView(isVisible : isVisible)) },
//        "Relevé bancaire"        : { isVisible in AnyView(BankStatementView(isVisible          : isVisible)) },
//        "Notes"                  : { isVisible in AnyView(NotesView(isVisible                  : isVisible)) },
//
//        // Rapport
//        "Categorie Bar1"         : { isVisible in AnyView(CategorieBar1View(isVisible         : isVisible)) },
//        "Categorie Bar2"         : { isVisible in AnyView(CategorieBar2View(isVisible         : isVisible)) },
//        "Mode de paiement"       : { isVisible in AnyView(ModePaiementView(isVisible          : isVisible)) },
//        "Recette Depense Bar"    : { isVisible in AnyView(RecetteDepenseBarView(isVisible     : isVisible)) },
//        "Recette Depense Pie"    : { isVisible in AnyView(RecetteDepensePieView(isVisible     : isVisible)) },
//        "Rubrique Bar"           : { isVisible in AnyView(RubriqueBarView(isVisible           : isVisible)) },
//        "Rubrique Pie"           : { isVisible in AnyView(RubriquePieView(isVisible           : isVisible)) },
//
//        // Reglage
//        "Identité"               : {  isVisible in AnyView(Identy(isVisible                   : isVisible)) },
//        "Echeancier"             : {  isVisible in AnyView(SchedulerView(isVisible            : isVisible)) },
//        "Réglage"                : {  isVisible in AnyView(SettingView(isVisible              : isVisible)) }
//    ]
//
//    var body: some View {
//        VStack {
//            if let detailView = localizedDetailView(for: selection2) {
//                detailView($isVisible)
//            } else {
//                Text("Content pour Sidebar 2 \(selection2 ?? "")")
//            }
//        }
//    }
//
//    func localizedDetailView(for selection: String?) -> ((Binding<Bool>) -> AnyView)? {
//        guard let selection = selection else { return nil }
//        return detailViews[localizeString(selection)]
//    }
//}
//
//struct SidebarDialogView: View {
//    var body: some View {
//        Spacer(minLength: 10)
//        OperationView(modeCreation: false)
//            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
//        Spacer(minLength: 10)
//    }
//}
//
//struct Sidebar1A: View {
//
//    @Binding var selection1: String?
//
//    var body: some View {
//
//        let accounts = Bundle.main.decode([DatasCompte].self, from: "Account.plist" )
//
//        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
//            let path = "Core Data SQLite file is located at: \(url.path)"
//        }
//
//        List(selection: $selection1) {
//            ForEach(accounts) { section in
//                Section(header: SectionHeader(section: section) ) {
//                    ForEach(section.children) { child in
//                        AccountRow(account: child)
//                            .tag(child.name)
//                    }
//                }
//            }
//        }
//        .navigationTitle("Account")
//        .listStyle(SidebarListStyle())
//        .frame(maxHeight: 500) // Pour ajuster la hauteur de la première barre latérale
//
//        Bouton()
//    }
//
//}
//
//// Vue pour l'en-tête de section
//struct SectionHeader: View {
//    let section: DatasCompte
//
//    var body: some View {
//
//        let balance: Double = section.children.reduce(0) { $0 + $1.solde }
//
//        HStack {
//            let count = section.children.count
//
//            Image(systemName: "folder.fill")
//                .foregroundColor(.accentColor)
//                .font(.system(size: 36)) // Ajustez la taille ici
//
//            VStack {
//                Text(section.type)
//                    .font(.headline)
//                Text("\(count) comptes")
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//            Text("\(balance, specifier: "%.2f") €")
//                .font(.headline)
//                .foregroundColor(.green)
//                .frame(width: 80, alignment: .trailing) // Aligne à droite avec une largeur fixe
//
//        }
//        .padding(.bottom, 5)
//    }
//}
//
//// Vue pour chaque ligne de compte
//struct AccountRow: View {
//    let account: DefAccount
//
//    var body: some View {
//        HStack {
//            Image(systemName: account.icon)
//                .foregroundColor(.blue)
//                .font(.system(size: 18)) // Ajustez la taille ici
//
//            VStack(alignment: .leading) {
//                Text(account.type)
//                    .font(.body)
//                    .foregroundColor(.black)
//                Text(account.name + " " + account.surName)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                Text(account.numAccount)
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//            Text( String(account.solde) + " €")
//                .font(.caption)
//                .foregroundColor(.green)
//                .frame(width: 80, alignment: .trailing) // Aligne à droite avec la même largeur fixe
//        }
//    }
//}
//
//struct Sidebar2A: View {
//
//    @Binding var selection2: String?
//
//    var body: some View {
//
//        let datas = Bundle.main.decode([Datas].self, from: "Feeds.plist" )
//
//        List(selection: $selection2) {
//            ForEach(datas) { section in
//                Section(localizeString(section.name)) {
//                    ForEach(section.children) { child in
//                        Label(child.name, systemImage: child.icon).tag(child.name)
//
//                            .font(.system(size: 12))
//                    }
//                }
//            }
//        }
//        .navigationTitle("Affichage")
//        .listStyle(SidebarListStyle())
//        .frame(maxHeight: .infinity) // Prend toute la place disponible
//    }
//}
//
//struct SidebarListView<T: Identifiable>: View {
//    let title: String
//    let items: [T]
//    @Binding var selection: String?
//    var labelProvider: (T) -> Label<Text, Image>
//
//    var body: some View {
//        List(selection: $selection) {
//            ForEach(items) { item in
//                labelProvider(item)
//                    .tag(item.id)
//            }
//        }
//        .navigationTitle(title)
//        .listStyle(SidebarListStyle())
//    }
//}
//
//struct Bouton: View {
//
//    @State private var selectedOption = "Options"
//
//    var body: some View {
//        HStack {
//            Button(action: {
//                print("Bouton moins appuyé")
//            }) {
//                Image(systemName: "minus.circle")
//                    .font(.system(size: 16))
//            }
//            Spacer()
//            Menu {
//                Button("Add Group Account", action: { selectedOption = "Add Group Account" })
//                Button("Add Account", action: { selectedOption = "Add Account" })
//            } label: {
//                Label(selectedOption, systemImage: "ellipsis.circle")
//                    .font(.system(size: 16))
//            }
//            Spacer()
//            Button(action: {
//                print("UUID")
//            }) {
//                Image(systemName: "lock")
//                    .font(.system(size: 16))
//            }
//        }
//        .padding(.horizontal)
//        .padding(.bottom, 10)
//    }
//}
//
//
