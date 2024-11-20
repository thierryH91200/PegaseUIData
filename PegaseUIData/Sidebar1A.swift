//
//  Sidebar1A.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 20/11/2024.
//

import SwiftUI
import AppKit
import SwiftData




struct Sidebar1A: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selection1: UUID?
    var body: some View {
        let entityAccounts = AccountManager.shared.getAllData( modelContext)

        List(selection: $selection1) {
            // Pré-filtrage des sections pour éviter les calculs complexes dans ForEach
            let headerSections = entityAccounts.filter { $0.isHeader }

            ForEach(headerSections, id: \.uuid) { section in
                Section(header: SectionHeader(section: section)) {
                    Text(section.name)
                        .tag(section.uuid)

                    // Utilisation d'une valeur par défaut pour les enfants
                    ForEach(section.children ?? [], id: \.uuid) { child in
                        AccountRow(account: child)
                            .tag(child.uuid)
                    }
                }
            }
        }
        .navigationTitle("Account")
        .listStyle(SidebarListStyle())
        .frame(maxHeight: 500) // Ajustement de la hauteur
        Bouton()
    }
}


class BalanceManager: ObservableObject {
    @Published var balance: Double = 123.45
}

//// Vue pour l'en-tête de section
struct SectionHeader: View {
    @ObservedObject var manager = BalanceManager()
    
    //        @State var balance: Double = 123 //section.children.reduce(0) { $0 + $1.solde }
    //        var balance: Double = section.children.reduce(0) { $0 + $1.solde }

    let section: EntityAccount

    var body: some View {
        
        HStack {
            let count = section.children!.count

            Image(systemName: "folder.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 36)) // Ajustez la taille ici

            VStack {
                Text(section.name)
                    .font(.headline)
                Text("\(count) Account")
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(manager.balance, specifier: "%.2f") €")
                .font(.headline)
                .foregroundColor(manager.balance >= 0 ? .green : .red)
                .frame(width: 80, alignment: .trailing) // Aligne à droite avec une largeur fixe
            // Boutons pour changer la balance (pour tester)
            HStack {
                Button("Increase") { manager.balance += 100 }
                Button("Decrease") { manager.balance -= 100 }
            }
            .padding()
        }
        .padding(.bottom, 5)
    }
}


//// Vue pour chaque ligne de compte
struct AccountRow: View {
    let account: EntityAccount

    var body: some View {
        HStack {
            Image(systemName: account.nameImage)
//            Image(systemName: "pencil")
                .foregroundColor(.blue)
                .font(.system(size: 18)) // Ajustez la taille ici

            VStack(alignment: .leading) {
                Text(String(account.name))
                    .font(.body)
                    .foregroundColor(.black)
                Text(account.identity!.name + " " + account.identity!.surName)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(account.initAccount!.codeAccount)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text( String(account.solde ?? 100.0) + " €")
                .font(.caption)
                .foregroundColor(.green)
                .frame(width: 80, alignment: .trailing) // Aligne à droite avec la même largeur fixe
        }
    }
}

struct Bouton: View {

    @State private var selectedOption = "Options"

    var body: some View {
        HStack {
            Button(action: {
                print("Bouton moins appuyé")
            }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16))
            }
            Spacer()
            Menu {
                Button("Add Group Account", action: { selectedOption = "Add Group Account" })
                Button("Add Account", action: { selectedOption = "Add Account" })
            } label: {
                Label(selectedOption, systemImage: "ellipsis.circle")
                    .font(.system(size: 16))
            }
            Spacer()
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

func getSQLiteFilePath() -> String? {
    guard let _ = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else { return nil}

    if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let path = "Core Data SQLite file is located at: \(url.path)"
        return path
    }
    return nil
}

struct AccountFactory {
    static func createAccount(modelContext: ModelContext, name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
        let account = EntityAccount()
        account.name = name
        account.nameImage = icon
        account.identity = EntityIdentity(name: idName, surName: idPrenom) // Assurez-vous que `EntityIdentity` existe avec un init dédié
        account.isAccount = true
        
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

struct initManager {
    static func initializeLibrary(modelContext: ModelContext) /*async*/ {
        
        let entities = AccountManager.shared.getRoot(modelContext: modelContext)
        if entities.isEmpty == true {
            /*await*/ setupForNilLibrary(modelContext: modelContext)
        }
    }

    static func setupForNilLibrary(modelContext: ModelContext) /*async*/ {
        // Création de l'élément racine
        let root = AccountFactory.createAccount(modelContext: modelContext, name: "Root", icon: "", idName: "", idPrenom: "", numAccount: "", type: 0)
        root.isRoot = true
        modelContext.insert(root)
        
        // Création des comptes
        let header1 = AccountFactory.createHeader(modelContext: modelContext, name: "Bank Account", parent: root)
        let header2 = AccountFactory.createHeader(modelContext: modelContext, name: "Save", parent: root)
        let header3 = AccountFactory.createHeader(modelContext: modelContext, name: "Bank Card", parent: root)
        
        let accountsConfig: [(name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int)] = [
            ("Current account", "banknote", "Martin", "Pierre", "00045700E", 0),
            ("Current account", "banknote", "Martin", "Marie", "00045701F", 0),
            ("Credit card", "creditcard", "Martin", "Pierre", "00045702G", 1),
            ("Credit card", "creditcard", "Durand", "Jean", "00045705K", 1),
            ("Save",            "building.columns", "Durand", "Jean", "00045703H", 2),
            ("Current account", "building.columns", "Durand", "Jean", "00045704J", 1)
        ]
        
        for config in accountsConfig[0...3] {
            let account = AccountFactory.createAccount(
                modelContext: modelContext,
                name: config.name,
                icon: config.icon,
                idName: config.idName,
                idPrenom: config.idPrenom,
                numAccount: config.numAccount,
                type: config.type
            )
            header1.addChild(account)
        }
        
        for config in accountsConfig[4...5] {
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
    }
    
    static func saveContext(_ modelContext: ModelContext) {
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



//struct Sidebar1A: View {
//
//    @Environment(\.modelContext) private var modelContext
//
//    @Binding var selection1: String?
//
//    var body: some View {
//
////        let accounts = Bundle.main.decode([DatasCompte].self, from: "Account.plist" )
//        let        entityAccounts = AccountManager.shared.getRoot(modelContext: modelContext)
//
//
////        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
////            let path = "Core Data SQLite file is located at: \(url.path)"
////        }
//
//        List(selection: $selection1) {
//            ForEach(entityAccounts.filter { $0.isHeader }) { section in
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
