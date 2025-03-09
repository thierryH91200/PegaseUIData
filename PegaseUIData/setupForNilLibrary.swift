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
        
        let identity = EntityIdentity(name: idName, surName: idSurName, account: account)
        account.identity = identity
        
        let banqueInfo = EntityBanqueInfo(account: account)
        account.bank = banqueInfo
        
        let initAccount = EntityInitAccount(account: account)
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount

        PaymentModeManager.shared.configure(with: modelContext)
        PaymentModeManager.shared.defaultModePaiement(for: account)
        account.paymentMode = PaymentModeManager.shared.entities
        
        StatusManager.shared.configure(with: modelContext)
        StatusManager.shared.defaultStatus(account: account)
        account.status = StatusManager.shared.entityStatus
        
        RubricManager.shared.configure(with: modelContext)  
        RubricManager.shared.defaultRubric(for: account)
        let rubric = RubricManager.shared.getAllDatas(account: account)
        account.rubric = rubric

        PreferenceManager.shared.configure(with: modelContext)
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
    var modelContext : ModelContext?
    var validContext : ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    private init() { }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func initialize() {
        AccountManager.shared.configure(with: validContext)
        let entities = AccountManager.shared.getRoot(modelContext: validContext)
        guard entities.isEmpty == true else { return }
        setupDefaultLibrary()
    }
    
    func setupDefaultLibrary() {
        
        // Création des comptes
        let folder1 = AccountFactory.createHeader(modelContext: validContext, name: "Bank Account")
        let folder2 = AccountFactory.createHeader(modelContext: validContext, name: "Save")
        
        let accountsConfig: [(name: String, icon: String, idName: String, idSurname: String, numAccount: String)] = [
            ("Current account1", DefaultIcons.currentAccount, "Martin", "Pierre", "00045700E"),
            ("Current account2", DefaultIcons.currentAccount, "Martin", "Marie", "00045701F"),
            ("Credit card1"    , DefaultIcons.creditCard, "Martin", "Pierre", "00045702G"),
            ("Credit card2"    , DefaultIcons.creditCard, "Durand", "Jean", "00045705K"),
            ("Save"            , DefaultIcons.currentAccount, "Durand", "Jean", "00045703H"),
            ("Current account3", DefaultIcons.currentAccount, "Durand", "Sarah", "00045704J")
        ]
        
        for config in accountsConfig[0...3] {
            var account = AccountFactory.createAccount(
                modelContext: validContext,
                name: config.0,
                icon: config.1 )
            
            account = AccountFactory.createOptionAccount(
                modelContext: validContext,
                account : account,
                idName: config.2,
                idSurName: config.3,
                numAccount: config.4)
            folder1.addChild(account)
        }

        for config in accountsConfig[4...5] {
            var account = AccountFactory.createAccount(
                modelContext: validContext,
                name: config.0,
                icon: config.1
            )
            account = AccountFactory.createOptionAccount(
                modelContext: validContext,
                account : account,
                idName: config.2,
                idSurName: config.3,
                numAccount: config.4)
            folder2.addChild(account)
        }
        
        // Enregistrer les dossiers
        validContext.insert(folder1)
        validContext.insert(folder2)
        
        // Enregistrement des modifications
        saveContext()
    }
    
    func saveContext() {
        if let path = getSQLiteFilePath() {
            print(path)
        } else {
            print("Erreur : chemin SQLite introuvable.")
        }
        do {
            try validContext.save()
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur : \(error.localizedDescription)")
        }
    }
}
