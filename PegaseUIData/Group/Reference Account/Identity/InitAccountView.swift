//
//  AccountView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

final class AccountInfoManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var initAccount: EntityInitAccount? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    func saveChanges(using context: ModelContext? = nil) {
        guard let context = context else { return }
        
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde des modifications : \(error)")
        }
    }
}

struct AccountView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var accountInfoManager: AccountInfoManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager

    @Query private var banqueInfos: [EntityInitAccount]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Logo et Rapport Initial
            if let initAccount = accountInfoManager.initAccount {
                HStack(alignment: .top) {
                    Image(systemName: "building.columns.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Initial report")
                            .font(.headline)
                        
                        HStack(spacing: 40) {
                            ReportView( initAccount: initAccount)
                        }
                    }
                }
            }

            // Références Bancaires
            if let initAccount = accountInfoManager.initAccount {
                VStack(alignment: .leading) {
                    Text("Bank references")
                        .font(.headline)
                    BankReferenceView(initAccount: initAccount)
                }
                .padding()
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
        .frame(width: 800, height: 600)
        .onAppear {
            withAnimation {
                initializeData()
            }
        }
        .onDisappear {
            resetAccount()
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            
            if let account = newAccount {
                accountInfoManager.initAccount = nil
                accountInfoManager.currentAccount = account
                
                loadOrCreateIdentity(for: account)
            }
        }
        .onChange(of: accountInfoManager.initAccount) { old , _ in
            do {
                try modelContext.save()
            } catch {
                print("Erreur lors de la sauvegarde : \(error)")
            }
        }

    }
    
    private func initializeData() {
        initializeCurrentAccount()
        createAccountIfNeeded()
    }
    
    private func initializeCurrentAccount() {
        if let account = currentAccountManager.currentAccount {
            accountInfoManager.currentAccount = account
        }
    }

    private func createAccountIfNeeded() {
        if accountInfoManager.initAccount == nil {
            if let account = CurrentAccountManager.shared.getAccount() {
                accountInfoManager.currentAccount = account
            } else {
                print("Aucun compte de disponible.")
            }
            InitAccountManager.shared.configure(with: modelContext)
            let accountInitInfo = InitAccountManager.shared.getAllDatas()
            accountInfoManager.initAccount = accountInitInfo ?? {
                let newInitAccount = EntityInitAccount()
                modelContext.insert(newInitAccount)
                return newInitAccount
            }()
        }
    }
    
    private func resetAccount() {
        saveChanges()
        accountInfoManager.saveChanges(using: modelContext)
        accountInfoManager.initAccount = nil
    }
    
    private func loadOrCreateIdentity(for account: EntityAccount) {
        
        IdentityManager.shared.configure(with: modelContext)
        if let existingInitAccount = InitAccountManager.shared.getAllDatas() {
            accountInfoManager.initAccount = existingInitAccount
        } else {
            let newInitAccount = EntityInitAccount()
            newInitAccount.account = account
            modelContext.insert(newInitAccount)
            accountInfoManager.initAccount = newInitAccount
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
}

// Vue pour le rapport initial (Planned, Engaged, Executed)
struct ReportView: View {
    
    @Environment(\.modelContext) var modelContext

    @Bindable var initAccount: EntityInitAccount
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Planned")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter planned value", text: Binding(
                get: { String(initAccount.prevu) }, // Convertir en String pour l'affichage
                set: { newValue in
                    if let value = Double(newValue) { // Convertir en Double pour le stockage
                        initAccount.prevu = value
                    }
                }
            ))
            .font(.title3)
            .bold()
            .onSubmit {
                saveChanges()
            }
        }
        
        VStack(alignment: .leading) {
            Text("Engaged")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter Engaged value", text: Binding(
                get: { String(initAccount.engage) }, // Convertir en String pour l'affichage
                set: { newValue in
                    if let value = Double(newValue) { // Convertir en Double pour le stockage
                        initAccount.engage = value
                    }
                }
            ))
            .font(.title3)
            .bold()
            .onSubmit {
                saveChanges()
            }
        }
        
        VStack(alignment: .leading) {
            Text("Executed")
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter Executed value", text: Binding(
                get: { String(initAccount.realise) }, // Convertir en String pour l'affichage
                set: { newValue in
                    if let value = Double(newValue) { // Convertir en Double pour le stockage
                        initAccount.realise = value
                    }
                }
            ))
            .font(.title3)
            .bold()
            .onSubmit {
                saveChanges()
            }
        }
    }
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
}

// Vue pour les références bancaires
struct BankReferenceView: View {
    
    @Environment(\.modelContext) var modelContext
    @Bindable var initAccount: EntityInitAccount

    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bank")
                    .frame(width: 100, alignment: .leading)
                TextField("Bank", text: $initAccount.codeBank)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            HStack {
                Text("Indicative")
                    .frame(width: 100, alignment: .leading)
                TextField("Indicative", text: $initAccount.codeGuichet)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Account")
                    .frame(width: 100, alignment: .leading)
                TextField("Account", text: $initAccount.codeAccount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Key")
                    .frame(width: 100, alignment: .leading)
                TextField("Key", text: $initAccount.cleRib)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("IBAN")
                    .frame(width: 100, alignment: .leading)
                TextField("IBAN", text: Binding(
                    get: { formattedIBAN(initAccount.iban) },
                    set: { newValue in
                        initAccount.iban = newValue.replacingOccurrences(of: " ", with: "") // Nettoyer pour stocker sans espaces
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
            }
            
            HStack {
                Text("BIC")
                    .frame(width: 100, alignment: .leading)
                TextField("BIC", text: $initAccount.bic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            .onChange(of: initAccount) {old, _ in saveChanges() }

        }
        .padding()
    }
    
    func formattedIBAN(_ iban: String) -> String {
        let cleanedIBAN = iban.replacingOccurrences(of: " ", with: "") // Retirer les espaces existants
        let groups = stride(from: 0, to: cleanedIBAN.count, by: 4).map { index in
            let start = cleanedIBAN.index(cleanedIBAN.startIndex, offsetBy: index)
            let end = cleanedIBAN.index(start, offsetBy: 4, limitedBy: cleanedIBAN.endIndex) ?? cleanedIBAN.endIndex
            return String(cleanedIBAN[start..<end])
        }
        return groups.joined(separator: " ") // Rejoindre les groupes avec des espaces
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

}
