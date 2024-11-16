//
//  setupForNilLibrary.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI
import SwiftData

@Observable
final class  setUpInit {
    
    private var modelContext : ModelContext?
    
    static let shared = setUpInit()
    
    init() {
        self.modelContext = nil
    }
    
    func initializeLibrary(modelContext: ModelContext) {
        self.modelContext = modelContext
        let entities = AccountManager.shared.getRoot(modelContext: modelContext)
        
        if entities.isEmpty == true {
            self.setupForNilLibrary()
        }
    }
    
    func setupForNilLibrary() {
        // Création de l'élément racine
        let root = EntityAccount()
        root.isRoot = true
        root.name = "Root"
        root.uuid = UUID()
        
        // Création des comptes
        let pierreAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Localizations.Document.IdName",
            idPrenom: "Localizations.Document.IdPrenom",
            numAccount: "00045700E",
            type: 0
        )
        
        let marieAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Martin",
            idPrenom: "Marie",
            numAccount: "00045701F",
            type: 0
        )
        
        let carteDeCredit1 = createAccount(
            name: "Carte_de_crédit",
            icon: "discount",
            idName: "Martin",
            idPrenom: "Pierre",
            numAccount: "00045702G",
            type: 1
        )
        
        let saving = createAccount(
            name: "Document.Save",
            icon: "icons8-money-box-80",
            idName: "Durand",
            idPrenom: "Jean",
            numAccount: "00045703H",
            type: 2
        )
        
        let jeanAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Durand",
            idPrenom: "Jean",
            numAccount: "00045704J",
            type: 0
        )
        
        // Création des en-têtes
        let header1 = createHeader(name: "BankAccount", parent: root)
        let header2 = createHeader(name: "BankAccount", parent: root)
        
        // Ajout des comptes aux en-têtes
        header1.children?.append(pierreAccount)
        header1.children?.append(marieAccount)
        header1.children?.append(carteDeCredit1)
        header1.children?.append(saving)
        
        header2.children?.append(jeanAccount)
        
        // Enregistrement des modifications
        do {
            try modelContext!.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }
    
    private func createAccount(name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
        
        let account = EntityAccount()
        account.name = name
        account.nameImage = icon
        account .identity?.name = idName
        account.identity?.surName = idPrenom
        
        let initAccount = EntityInitAccount()
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount
        
        account.type = type
        account.uuid = UUID()
        return account
    }
    
    private func createHeader(name: String, parent: EntityAccount) -> EntityAccount {
        let header = EntityAccount()
        header.isHeader = true
        header.name = name
        header.uuid = UUID()
        header.parent = parent
        return header
    }
}



