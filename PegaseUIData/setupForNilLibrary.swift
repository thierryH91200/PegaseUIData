//
//  setupForNilLibrary.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

struct AccountFactory {
    static func createAccount(modelContext: ModelContext, name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
        guard !name.isEmpty, !icon.isEmpty else {
            fatalError("Nom ou icône invalide pour le compte.")
        }

        let account = EntityAccount()
        account.name = name
        account.nameImage = icon
        account.identity = EntityIdentity(name: idName, surName: idPrenom)
        account.isAccount = true
        account.type = type
        account.uuid = UUID()

        let initAccount = EntityInitAccount()
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount

        PaymentModeManager.shared.defaultModePaiement(for: account, context: modelContext)
        account.paymentMode = PaymentModeManager.shared.entities

        modelContext.insert(account)
        return account
    }

    static func createHeader(modelContext: ModelContext, name: String, parent: EntityAccount) -> EntityAccount {
        let header = EntityAccount()
        header.isHeader = true
        header.name = name
        header.nameImage = "folder.fill"
        header.uuid = UUID()
        header.parent = parent

        modelContext.insert(header)
        return header
    }
}

@Observable
final class InitManager {
    
    static let shared = InitManager()
    private var modelContext: ModelContext?
    
    private init() { }
    
    private enum DefaultIcons {
        static let currentAccount = "building.columns"
        static let savings = "icons8-money-box-80"
        static let creditCard = "creditcard"
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func initialize() /*async*/ {
        
        guard let modelContext = modelContext else {
            print("ModelContext non configuré. Veuillez appeler `configure` d'abord.")
            return
        }
        
        let entities = AccountManager.shared.getRoot(modelContext: modelContext)
        if entities.isEmpty == true {
            /*await*/ setupDefaultLibrary()
        }
    }
    
    func setupDefaultLibrary() /*async*/ {
        
        guard let modelContext = modelContext else {
            print("ModelContext non configuré. Veuillez appeler `configure` d'abord.")
            return
        }

        // Création de l'élément racine
        let root = AccountFactory.createAccount(modelContext: modelContext, name: "Root", icon: "", idName: "", idPrenom: "", numAccount: "", type: 0)
        root.isRoot = true
        modelContext.insert(root)
        
        // Création des comptes
        let header1 = AccountFactory.createHeader(modelContext: modelContext, name: "Bank Account", parent: root)
        let header2 = AccountFactory.createHeader(modelContext: modelContext, name: "Save", parent: root)
        
        let accountsConfig: [(name: String, icon: String, idName: String, idSurname: String, numAccount: String, type: Int)] = [
            ("Current account1", DefaultIcons.currentAccount, "Martin", "Pierre", "00045700E", 0),
            ("Current account2", DefaultIcons.currentAccount, "Martin", "Marie", "00045701F", 0),
            ("Credit card1"    , DefaultIcons.creditCard, "Martin", "Pierre", "00045702G", 1),
            ("Credit card2"    , DefaultIcons.creditCard, "Durand", "Jean", "00045705K", 1),
            ("Save"            , DefaultIcons.currentAccount, "Durand", "Jean", "00045703H", 2),
            ("Current account3", DefaultIcons.currentAccount, "Durand", "Sarah", "00045704J", 1)
        ]
        
        for config in accountsConfig[0...3] {
            let account = AccountFactory.createAccount(
                modelContext: modelContext,
                name: config.0,
                icon: config.1,
                idName: config.2,
                idPrenom: config.3,
                numAccount: config.4,
                type: config.5
            )
            header1.addChild(account)
        }
        
        for config in accountsConfig[4...5] {
            let account = AccountFactory.createAccount(
                modelContext: modelContext,
                name: config.0,
                icon: config.1,
                idName: config.2,
                idPrenom: config.3,
                numAccount: config.4,
                type: config.5
            )
            header2.addChild(account)
        }
        
        // Enregistrement des modifications
        saveContext(modelContext)
    }
    
    func saveContext(_ modelContext: ModelContext) {
        let path = getSQLiteFilePath()
        print(path!)
        do {
            try modelContext.save()
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur : \(error.localizedDescription)")
        }
    }
}




