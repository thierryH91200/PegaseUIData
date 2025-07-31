//
//  setupForNilLibrary.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

struct AccountFactory {
    static func createAccount(modelContext: ModelContext, name: String, icon: String) -> EntityAccount {
        
        let account = EntityAccount()
        account.name = name
        account.nameIcon = icon
        account.uuid = UUID()
        
        modelContext.insert(account)
        return account
    }
        
    static func createOptionAccount(modelContext: ModelContext, account : EntityAccount, idName: String, idSurName: String, numAccount: String) -> EntityAccount {
        
        CurrentAccountManager.shared.setAccount(account )
        
        let identity = EntityIdentity(name: idName, surName: idSurName, account: account)
        account.identity = identity
        
        let banqueInfo = EntityBanqueInfo(account: account)
        account.bank = banqueInfo
        
        let initAccount = EntityInitAccount(account: account)
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount
        
        DataContext.shared.context = modelContext

        PaymentModeManager.shared.createDefaultPaymentModes(for: account)
        account.paymentMode = PaymentModeManager.shared.modePayments
        
        StatusManager.shared.defaultStatus(account: account)
        account.status = StatusManager.shared.status
        
        RubricManager.shared.defaultRubric(for: account)
        let rubric = RubricManager.shared.getAllData(account: account)
        account.rubric = rubric

        let entityPreference = PreferenceManager.shared.defaultPref(account: account)
        account.preference = entityPreference
        
        modelContext.insert(account)
        return account
    }

    static func createHeader(modelContext: ModelContext, name: String) -> EntityFolderAccount {
        let header = EntityFolderAccount()
        header.name = name
        header.nameImage = "folder.fill"
        header.uuid = UUID()
        
        modelContext.insert(header)
        return header
    }
}

@Observable
final class InitManager {
    
    static let shared = InitManager()
        
    private enum DefaultIcons {
        static let currentAccount = "building.columns"
        static let savings = "banknote"
        static let creditCard = "creditcard"
    }
    
    // Contexte pour les modifications
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    private init() { }

    func initialize() {
        DataContext.shared.context = modelContext
        let entities = AccountManager.shared.getRoot(modelContext: modelContext!)
        guard entities.isEmpty == true else { return }
        setupDefaultLibrary()
    }
    
    func setupDefaultLibrary() {
        
        // Création des comptes
        let folder1 = AccountFactory.createHeader(modelContext: modelContext!, name: "Bank Account")
        let folder2 = AccountFactory.createHeader(modelContext: modelContext!, name: "Save")
        
        let typeAccounts : [String] = [
            String(localized :"Current account1",table : "Account"),
            String(localized :"Current account2",table : "Account"),
            String(localized :"Credit card1",table : "Account"),
            String(localized :"Credit card2",table : "Account"),
            String(localized :"Save",table : "Account"),
            String(localized :"Current account3",table : "Account")]
        
        let accountsConfig: [(name: String, icon: String, idName: String, idSurname: String, numAccount: String)] = [
            (typeAccounts[0], DefaultIcons.currentAccount, "Martin", "Pierre", "00045700E"),
            (typeAccounts[1], DefaultIcons.currentAccount, "Martin", "Marie", "00045701F"),
            (typeAccounts[2], DefaultIcons.creditCard, "Martin", "Pierre", "00045702G"),
            (typeAccounts[3], DefaultIcons.creditCard, "Durand", "Jean", "00045705K"),
            (typeAccounts[4], DefaultIcons.currentAccount, "Durand", "Jean", "00045703H"),
            (typeAccounts[5], DefaultIcons.currentAccount, "Durand", "Sarah", "00045704J")
        ]
        
        for config in accountsConfig[0...3] {
            var account = AccountFactory.createAccount(
                modelContext: modelContext!,
                name: config.0,
                icon: config.1 )
            
            account = AccountFactory.createOptionAccount(
                modelContext: modelContext!,
                account : account,
                idName: config.2,
                idSurName: config.3,
                numAccount: config.4)
            folder1.addChild(account)
        }

        for config in accountsConfig[4...5] {
            var account = AccountFactory.createAccount(
                modelContext: modelContext!,
                name: config.0,
                icon: config.1
            )
            account = AccountFactory.createOptionAccount(
                modelContext: modelContext!,
                account : account,
                idName: config.2,
                idSurName: config.3,
                numAccount: config.4)
            folder2.addChild(account)
        }
        
        // Enregistrer les dossiers
        modelContext?.insert(folder1)
        modelContext?.insert(folder2)
        
        // Enregistrement des modifications
        saveContext()
    }
    
    func saveContext() {
        if let path = getSQLiteFilePath() {
            printTag(path)
        } else {
            printTag("Erreur : chemin SQLite introuvable.")
        }
        do {
            try modelContext?.save()
            printTag("Sauvegarde réussie.")
        } catch {
            printTag("Erreur : \(error.localizedDescription)")
        }
    }
}
