import SwiftUI
import SwiftData
import AppKit


struct Sidebar1A: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EntityFolderAccount.name, animation: .bouncy) var folders: [EntityFolderAccount]
    
    @State private var modePayments : [EntityPaymentMode] = []
    
    @State private var selectedAccount: EntityAccount?
    @State private var selectedMode = "Check"
    
    var body: some View {
        
        List(selection: $selectedAccount) {
            
            ForEach(folders) { folder in
                Section(header: SectionHeader(section: folder)) {
                    
                    ForEach(folder.childrenSorted, id: \.id) { child in
                        AccountRow(account: child, isSelected: selectedAccount?.id == child.id)
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
                
                CurrentAccountManager.shared.setAccount(account)
                DataContext.shared.context = modelContext

                // Exécute le code asynchrone dans une Task
                Task {
                    let modes = PaymentModeManager.shared.getAllData()
                    
                    // Mettez à jour les données sur le thread principal
                    DispatchQueue.main.async {
                        withAnimation {
                            modePayments = modes!
                        }
                    }
                }
            } else {
                withAnimation {
                    modePayments = []
                }
            }
        }
        .onAppear {
            Task {
                Sidebar1A.preloadDataIfNeeded(modelContext: modelContext)
                await MainActor.run {
                    if selectedAccount == nil, let firstFolder = folders.first, let firstAccount = firstFolder.children.first {
                        selectedAccount = firstAccount
                        selectedMode = firstAccount.paymentMode?.first?.name ?? ""
                    }
                }
            }
        }
        Bouton()
    }
    
    static func preloadDataIfNeeded(modelContext: ModelContext) {
        // Vérifie si des données existent déjà
        let existingFolders = try? modelContext.fetch(FetchDescriptor<EntityFolderAccount>())
        guard existingFolders?.isEmpty == true else { return }
        
        // Ajout de données d'exemple
        let folder1 = EntityFolderAccount()
        folder1.name = String(localized:"Bank Account")
        
        var account1 = AccountFactory.createAccount(modelContext: modelContext, name: String(localized:"Current account1"), icon: "dollarsign.circle")
        account1 = AccountFactory.createOptionAccount(modelContext: modelContext, account: account1, idName: "Martin", idSurName: "Pierre", numAccount: "00045700E")
        
        var account2 = AccountFactory.createAccount(modelContext: modelContext, name: String(localized:"Current account2"), icon: "eurosign.circle")
        account2 = AccountFactory.createOptionAccount(modelContext: modelContext, account: account2, idName: "Martin", idSurName: "Marie", numAccount: "00045701F")
        
        folder1.children = [
            account1, account2 ]
        
        let folder2 = EntityFolderAccount()
        folder2.name = String(localized:"Save")
        
        var account3 = AccountFactory.createAccount(modelContext: modelContext, name: String(localized:"Current account3"), icon: "calendar.circle")
        account3 = AccountFactory.createOptionAccount(modelContext: modelContext, account: account3, idName: "Durand", idSurName: "Jean", numAccount: "00045703H")
        
        folder2.children = [
            account3 ]
        
        // Enregistrer les dossiers
        modelContext.insert(folder1)
        modelContext.insert(folder2)
        
        try? modelContext.save()
    }
}

class BalanceManager: ObservableObject {
    @Published var balance: Double = 123.45
}

//// Vue pour l'en-tête de section
struct SectionHeader: View {
    @ObservedObject var manager = BalanceManager()
    
    @State var balance: Double = 0.0 //section.children.reduce(0) { $0 + $1.solde }
    
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
            
            // Boutons pour changer la balance (pour tester)
//            HStack {
//                Button("Increase") { manager.balance += 100 }
//                Button("Decrease") { manager.balance -= 100 }
//            }
//            .padding()
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
                printTag("Button minus pressed")
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
                printTag("UUID")
            }) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

