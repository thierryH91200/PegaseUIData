//
//  exemple4.swift
//  PegaseUI
//
//  Created by Thierry hentic on 27/10/2024.
//

import SwiftUI
import Foundation
import AppKit

struct ContentView100: View {
    @State private var selection1: String? = "John"
    @State private var selection2: String? = localizeString("Liste des transactions")
    @State private var isVisible: Bool = true
    
    @State private var inspectorIsShown: Bool = false

    
    var body: some View {
        HStack
        {
            NavigationSplitView {
                SidebarContainer(selection1: $selection1, selection2: $selection2)
            }
            content :
            {
                DetailContainer(selection2: $selection2, isVisible: $isVisible)
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
            .alignmentGuide(.trailing) { _ in isVisible ? 200 : 0 }
            Spacer(minLength: 10)

        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    print("Nouvel élément ajouté")
                }) {
                    Label("Ajouter", systemImage: "plus")
                }
                
                Button(action: {
                    print("Recherche effectuée")
                }) {
                    Label("Rechercher", systemImage: "magnifyingglass")
                }
                
                Spacer()
                Button {
                    inspectorIsShown.toggle()
                } label: {
                    Label("Show inspector",
                          systemImage: "sidebar.right")
                }

                
                Button(action: {
                    print("Paramètres ouverts")
                }) {
                    Label("Paramètres", systemImage: "gear")
                }
                Toggle(isOn: $isVisible) {
                    Image(systemName: "sidebar.trailing")
                }
                .toggleStyle(.button)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

struct SidebarContainer: View {
    @Binding var selection1: String?
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
        "Identité"               : {  isVisible in AnyView(IdentyView(isVisible               : isVisible)) },
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
        return detailViews[localizeString(selection)]
    }
}

struct SidebarDialogView: View {
    var body: some View {
        Spacer(minLength: 10)
        OperationView(modeCreation: false)
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
        Spacer(minLength: 10)
    }
}

struct Sidebar1A: View {
    
    @Binding var selection1: String?
    
    var body: some View {
        
        let accounts = Bundle.main.decode([DatasCompte].self, from: "Account.plist" )
        
        List(selection: $selection1) {
            ForEach(accounts) { section in
                Section(header: SectionHeader(section: section) ) {
                    ForEach(section.children) { child in
                        AccountRow(account: child)
                            .tag(child.name)
                    }
                }
            }
        }
        .navigationTitle("Account")
        .listStyle(SidebarListStyle())
        .frame(maxHeight: 500) // Pour ajuster la hauteur de la première barre latérale
        
        Bouton()
    }

}

// Vue pour l'en-tête de section
struct SectionHeader: View {
    let section: DatasCompte
    
    var body: some View {
        
        let balance: Double = section.children.reduce(0) { $0 + $1.solde }
        
        HStack {
            let count = section.children.count
            
            Image(systemName: "folder.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 36)) // Ajustez la taille ici
            
            VStack {
                Text(section.type)
                    .font(.headline)
                Text("\(count) comptes")
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(balance, specifier: "%.2f") €")
                .font(.headline)
                .foregroundColor(.green)
                .frame(width: 80, alignment: .trailing) // Aligne à droite avec une largeur fixe
            
        }
        .padding(.bottom, 5)
    }
}

// Vue pour chaque ligne de compte
struct AccountRow: View {
    let account: DefAccount
    
    var body: some View {
        HStack {
            Image(systemName: account.icon)
                .foregroundColor(.blue)
                .font(.system(size: 18)) // Ajustez la taille ici

            VStack(alignment: .leading) {
                Text(account.type)
                    .font(.body)
                    .foregroundColor(.black)
                Text(account.name + " " + account.surName)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(account.numAccount)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text( String(account.solde) + " €")
                .font(.caption)
                .foregroundColor(.green)
                .frame(width: 80, alignment: .trailing) // Aligne à droite avec la même largeur fixe
        }
    }
}



struct Sidebar2A: View {
    
    @Binding var selection2: String?
    
    var body: some View {
        
        let datas = Bundle.main.decode([Datas].self, from: "Feeds.plist" )
        
        List(selection: $selection2) {
            ForEach(datas) { section in
                Section(localizeString(section.name)) {
                    ForEach(section.children) { child in
                        Label(child.name, systemImage: child.icon).tag(child.name)
                        
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .navigationTitle("Affichage")
        .listStyle(SidebarListStyle())
        .frame(maxHeight: .infinity) // Prend toute la place disponible
    }
}

struct SidebarListView<T: Identifiable>: View {
    let title: String
    let items: [T]
    @Binding var selection: String?
    var labelProvider: (T) -> Label<Text, Image>
    
    var body: some View {
        List(selection: $selection) {
            ForEach(items) { item in
                labelProvider(item)
                    .tag(item.id)
            }
        }
        .navigationTitle(title)
        .listStyle(SidebarListStyle())
    }
}

struct Bouton: View {
    
    @State private var selectedOption = ""
    //    @State var  UUID : UUID
    
    var body: some View {
        
        HStack {
            // Bouton "Moins"
            Button(action: {
                print("Bouton moins appuyé")
            }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            // Pop-up bouton (Menu)
            Menu {
                Button("", action: { selectedOption = "" })
                Button("Add Group Account", action: { selectedOption = "Add Group Account" })
                Button("Add Account", action: { selectedOption = "Add Account" })
            } label: {
                Label(selectedOption, systemImage: "ellipsis.circle")
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            // Bouton Cadenas
            Button(action: {
                print("UUID")
            }) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

