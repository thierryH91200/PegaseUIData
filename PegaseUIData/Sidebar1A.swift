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
    @State private var selectedEntity: EntityAccount? // Entité sélectionnée

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
        .onChange(of: selection1) { _, newSelection in
            // Trouver et stocker l'entité sélectionnée
            selectedEntity = entityAccounts.first(where: { $0.uuid == newSelection })
            print("Selected Entity: \(String(describing: selectedEntity!.name))")
            CurrrentAccountManager.shared.setAccount(selectedEntity!)
        }
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
            let count = section.children?.count ?? 0

            Image(systemName: section.nameImage)
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
            Text("\(account.solde ?? 100.0, specifier: "%.2f") €")                .font(.caption)
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
                print("Button minus pressed")
            }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16))
            }
            Spacer()
            Menu {
                Button(String(localized: "Add Group Account"), action: { selectedOption = "Add Group Account" })
                Button(String(localized:"Add Account"), action: { selectedOption = "Add Account" })
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





