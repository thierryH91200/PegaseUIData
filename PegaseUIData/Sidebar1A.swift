import SwiftUI
import SwiftData
import AppKit
import Combine

//extension EntityFolderAccount: Identifiable {}
//extension EntityAccount: Identifiable {}

struct Sidebar1A: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State var folders: [EntityFolderAccount] = []
    
    //    @State private var isShowAccountFormView = false
    //    @State private var isShowGroupFormView = false
    //    @State private var isModeCreate = false
    
    
    @State private var selectedAccountID: UUID?
    @State private var selectedMode = "Check"
    
    var body: some View {
        
        List(selection: $selectedAccountID) {
            ForEach(folders) { folder in
                FolderSectionView(
                    folder: folder,
                    selectedAccountID: $selectedAccountID
                )
            }
        }
        .navigationTitle("Account")
        .listStyle(SidebarListStyle())
        .id(selectedAccountID)
        .frame(maxHeight: 500) // Ajustement de la hauteur
        
        .onChange(of: selectedAccountID) { oldID, newID in
            if let uuid = newID?.uuidString {
                CurrentAccountManager.shared.setAccount(uuid)
            }
        }
        Bouton(selectedAccountID: $selectedAccountID)
            .onAppear {
                Task {
                    folders = AccountFolderManager.shared.getAllData()
                    AccountFolderManager.shared.preloadDataIfNeeded(modelContext: modelContext)
                    await MainActor.run {
                        if selectedAccountID == nil {
                            if let firstFolder = folders.first, let firstAccount = firstFolder.children.first {
                                selectedAccountID = firstAccount.uuid
                                let firstModeName: String = firstAccount.paymentMode?.first?.name ?? ""
                                selectedMode = firstModeName
                            }
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
    
    @State var balance: Double = 0.0
    //section.children.reduce(0) { $0 + $1.solde }
    
    let section: EntityFolderAccount
    
    var body: some View {
        
        let count: Int = section.children.count
        
        HStack {
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
            Text("\(balance, specifier: "%.2f") €")
                .font(.headline)
                .foregroundColor(balance >= 0 ? .green : .red)
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
    let isSelected: Bool
    var onAdd: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed properties optimisées
    
    private var rowBackground: Color {
        if isSelected {
            return colorScheme == .dark
            ? Color.accentColor.opacity(0.5)
            : Color.accentColor.opacity(0.6)
        } else {
            return colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.clear
        }
    }
    
    private var iconBackground: Color {
        isSelected ? Color.accentColor : Color.gray.opacity(0.3)
    }
    
    private var soldeColor: Color {
        account.solde >= 0 ? .green : .red
    }
    
    private var identityText: String? {
        guard let id = account.identity else { return nil }
        return "\(id.name) \(id.surName)"
    }
    
    private var accountCodeText: String? {
        account.initAccount?.codeAccount
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            icon
            info
            Spacer()
            solde
        }
        .padding(8)
        .background(rowBackground)
        .cornerRadius(6)
        .contextMenu {
            menu
        }
    }
    
    // MARK: - Sous-vues
    
    private var icon: some View {
        Image(systemName: account.nameIcon)
            .foregroundColor(.white)
            .padding(6)
            .background(iconBackground)
            .clipShape(Circle())
    }
    
    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            
            Text(account.name)
                .font(.body)
                .foregroundColor(isSelected ? .white : .primary)
            
            if let identityText {
                Text(identityText)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            if let accountCodeText {
                Text(accountCodeText)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
    }
    
    private var solde: some View {
        Text("\(account.solde, specifier: "%.2f") €")
            .font(.caption)
            .foregroundColor(soldeColor)
            .frame(width: 80, alignment: .trailing)
    }
    
    private var menu: some View {
        Group {
            Button { onAdd?() } label: {
                Label("Add account", systemImage: "arrow.right.circle")
            }
            
            Button { onEdit?() } label: {
                Label("Edit account", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) { onDelete?() } label: {
                Label("Remove account", systemImage: "trash")
            }
        }
    }
}

//struct AccountRow: View {
//    let account: EntityAccount
//    var isSelected: Bool
//    var onAdd: (() -> Void)?
//    var onEdit: (() -> Void)?
//    var onDelete: (() -> Void)?
//    
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        HStack {
//            Image(systemName: account.nameIcon)
//                .foregroundColor(.white)
//                .padding(6)
//                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
//                .clipShape(Circle())
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(String(account.name))
//                    .font(.body)
//                    .foregroundColor(isSelected ? .white : .primary)
//                if let identity = account.identity {
//                    Text(identity.name + " " + identity.surName)
//                        .font(.caption)
//                        .foregroundColor(isSelected ? .white : .primary)
//                }
//                if let initAcc = account.initAccount {
//                    Text(initAcc.codeAccount)
//                        .font(.caption2)
//                        .foregroundColor(isSelected ? .white : .primary)
//                }
//            }
//            Spacer()
//            Text("\(account.solde, specifier: "%.2f") €")
//                .font(.caption)
//                .foregroundColor(account.solde >= 0 ? .green : .red)
//                .frame(width: 80, alignment: .trailing)
//        }
//        .padding(8)
//        .background(
//            isSelected
//            ? (colorScheme == .dark ? Color.accentColor.opacity(0.5) : Color.accentColor.opacity(0.6))
//            : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.clear)
//        )
//        .cornerRadius(6)
//        .contextMenu {
//            Button {
//                onAdd?()
//            } label: {
//                Label("Add account", systemImage: "arrow.right.circle")
//            }
//            
//            Button {
//                onEdit?()
//            } label: {
//                Label("Edit account", systemImage: "pencil")
//            }
//            Divider()
//            
//            Button(role: .destructive) {
//                onDelete?()
//            } label: {
//                Label("Remove account", systemImage: "trash")
//            }
//        }
//        
//    }
//}

struct Bouton: View {
    
    @Binding var selectedAccountID: UUID?
    
    @State private var selectedOption = "Options"
    
    @State private var isShowAccountFormView = false
    @State private var isShowGroupFormView = false
    @State private var isModeCreate = false
    
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
                Button(action: {
                    isShowGroupFormView = true
                    isModeCreate = true
                }) {
                    Label(String(localized:"Add Group Account"), systemImage: "info.circle")
                }
                Button(action: {
                    isShowGroupFormView = true
                    isModeCreate = false
                }) {
                    Label("Edit Group Account", systemImage: "info.circle")
                }
                Divider()
                
                Button(String(localized:"Add Account"),
                       action: {
                    isShowAccountFormView = true
                    isModeCreate = true
                })
                Button(action: {
                    isShowAccountFormView = true
                    isModeCreate = false
                }) {
                    Label("Edit account", systemImage: "info.circle")
                }
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
        .sheet(isPresented: $isShowAccountFormView , onDismiss: {setupDataManager()})
        {
            AccountFormView(
                isPresented: $isShowAccountFormView,
                isModeCreate: $isModeCreate,
                account: nil)
        }
        .sheet(isPresented: $isShowGroupFormView , onDismiss: {setupDataManager()})
        {
            GroupAccountFormView(
                isPresented: $isShowGroupFormView,
                isModeCreate: $isModeCreate,
                accountFolder: nil)
        }
    }
    
    private func setupDataManager() {
        
    }
}

struct AccountFormView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    
    @State var name: String = ""
    @State var surName: String = ""
    @State var libelle: String = ""
    @State var soldeInit: String = ""
    @State var numero: String = ""
    
    let account: EntityAccount?
    
    var body: some View {
        Text("AccountFormView")
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
        
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Text(String(localized:"Name", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Prénom", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $surName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Libellé", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $libelle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Solde initial", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $soldeInit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Numéro compte", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $numero)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized:"Cancel", table: "Settings")) {
                    isPresented = false
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized:"Save", table: "Settings")) {
                    isPresented = false
                    //                        save()
                    dismiss()
                }
                .disabled(name.isEmpty )
                .opacity( name.isEmpty ? 0.6 : 1)
            }
        }
        .frame(width: 400)
        
        // Bandeau du bas
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
    }
}

struct GroupAccountFormView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    
    let accountFolder: EntityFolderAccount?
    
    @State var name: String = ""
    @State var nameImage: String = ""
    
    var body: some View {
        Text("GroupAccountFormView")
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
        
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Text(String(localized:"Name", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack(spacing: 20) {
                    Text(String(localized:"Name Image", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $nameImage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
            }
            
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized:"Cancel", table: "Settings")) {
                    isPresented = false
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized:"Save", table: "Settings")) {
                    isPresented = false
                    save()
                    dismiss()
                }
                .disabled(name.isEmpty )
                .opacity( name.isEmpty ? 0.6 : 1)
            }
        }
        .frame(width: 400)
        
        // Bandeau du bas
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
    }
    
    private func save() {
        if isModeCreate { // Création
            AccountFolderManager.shared.create(
                name: name,
                nameImage: nameImage)
        } else { // Modification
            if let existingItem = accountFolder {
                existingItem.name = name
                existingItem.nameImage = nameImage
                AccountFolderManager.shared.save()
            }
        }
        isPresented = false
        dismiss()
    }
}

struct FolderSectionView: View {
    let folder: EntityFolderAccount
    @Binding var selectedAccountID: UUID?

    var body: some View {
        Section(header: SectionHeader(section: folder)) {
            ForEach(folder.childrenSorted) { child in
                AccountRow(
                    account: child,
                    isSelected: (selectedAccountID == child.uuid),
                    onAdd: {
                        print("Add account")
                        selectedAccountID = child.uuid },
                    onEdit: {
                        print("Edit account") },
                    onDelete: {
                        print("Remove account")
                        AccountManager.shared.delete(account: child) }
                )
                .tag(child.uuid)
            }
        }
    }
}
