import SwiftUI
import SwiftData
import AppKit
import Combine



struct Sidebar1A: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State var folders: [EntityFolderAccount] = []
    
    @State private var selectedAccount: EntityAccount?
    @State private var selectedMode = "Check"
    
    var body: some View {
        
        List(selection: $selectedAccount) {
            
            ForEach(folders) { folder in
                Section(header: SectionHeader(section: folder)) {
                    
                    ForEach(folder.childrenSorted, id: \.uuid) { child in
                        AccountRow(account: child, isSelected: selectedAccount?.uuid == child.uuid)
                            .tag(child)
                    }
                }
            }
        }
        .navigationTitle("Account")
        .listStyle(SidebarListStyle())
        .frame(maxHeight: 500) // Ajustement de la hauteur
        
        .onChange(of: selectedAccount) { oldAccount, newAccount in
            if let account = newAccount {
                
                let uuidString = account.uuid.uuidString
                CurrentAccountManager.shared.setAccount(uuidString)
            }
        }
        Bouton()
        .onAppear {
            Task {
                folders = AccountFolderManager.shared.getAllData()
                AccountFolderManager.shared.preloadDataIfNeeded(modelContext: modelContext)
                await MainActor.run {
                    if selectedAccount == nil, let firstFolder = folders.first, let firstAccount = firstFolder.children.first {
                        selectedAccount = firstAccount
                        selectedMode = firstAccount.paymentMode?.first?.name ?? ""
                    }
                }
            }
        }
    }
}

class BalanceManager: ObservableObject {
    @Published var balance: Double = 123.45
}

//// Vue pour l'en-tête de section
struct SectionHeader: View {
    @ObservedObject var manager = BalanceManager()
    
    @State var balance: Double = 0.0
    //section.children.reduce(0) { $0 + $1.solde }
    
    let section: EntityFolderAccount
    
    var body: some View {
        
        HStack {
            let count = section.children.count
            
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
        }
        .onAppear(){
            balance = section.children.reduce(0) { $0 + $1.solde }
        }
        .padding(.bottom, 5)
    }
}



struct AccountRow: View {
    let account: EntityAccount
    var isSelected: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Image(systemName: account.nameIcon)
                .foregroundColor(.white)
                .padding(6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(String(account.name))
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(account.identity!.name + " " + account.identity!.surName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                Text(account.initAccount!.codeAccount)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            Spacer()
            Text("\(account.solde, specifier: "%.2f") €")
                .font(.caption)
                .foregroundColor(account.solde >= 0 ? .green : .red)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(8)
        .background(
            isSelected
                ? (colorScheme == .dark ? Color.accentColor.opacity(0.5) : Color.accentColor.opacity(0.6))
                : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear)
        )
        .cornerRadius(6)
    }
}

struct Bouton: View {
    
    @State private var selectedOption = "Options"
    
    var body: some View {
        HStack {
            Button(action: {
                printTag("Button minus pressed", flag: true)
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
                printTag("UUID", flag: true)
            }) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

