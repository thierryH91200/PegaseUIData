//
//  EntityAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI

@Model public class EntityFolderAccount: Identifiable  {
    
    var name: String = ""
    var nameImage: String = "folder.fill"
    var isRoot : Bool = false

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    var children: [EntityAccount] = []
    
    public init() {
    }
    
    public init(name: String, isRoot: Bool, children: [EntityAccount]) {
        self.name = name
        self.children = children
    }
}

extension EntityFolderAccount {
    func addAccounts(_ accounts: [EntityAccount]) {
        for account in accounts {
            self.addChild(account)
        }
    }
    
    func addChild(_ child: EntityAccount) {
        if children.isEmpty == true {
            children = []
        }
        children.append(child)
    }
}


@Model public class EntityAccount: Identifiable {

    var name: String = ""
    var nameIcon: String = ""
    @Attribute(.ephemeral) var solde: Double? = 0.0
    var dateEcheancier: Date = Date().noon
    var isDemo : Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \EntitySchedule.account)
    var echeanciers: [EntitySchedule]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityIdentity.account)
    var identity: EntityIdentity?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityInitAccount.account)
    var initAccount: EntityInitAccount?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityPaymentMode.account)
    var paymentMode: [EntityPaymentMode]?

    @Relationship(deleteRule: .cascade, inverse: \EntityBank.account)
    var bank: EntityBank?
    
    @Relationship(inverse: \EntityBankStatement.account)
    var bankStatement: [EntityBankStatement]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityCarnetCheques.account)
    var carnetCheques: [EntityCarnetCheques]?

    var compteLie: EntitySchedule?

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init() {
    }
    
    public init(name: String, nameIcon: String) {
        self.name = name
        self.nameIcon = nameIcon
    }
}

final class AccountManager {
      
    static let shared = AccountManager()
    var entities = [EntityFolderAccount]()
    
    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }
    
    init() { }
    
    @discardableResult
    public func configure(with modelContext: ModelContext) -> Bool {
        self.modelContext = modelContext
        return true
    }

    func getAllData(modelContext: ModelContext) -> [EntityFolderAccount] {
        do {
            // Exécution d'une requête manuelle si besoin de filtrer ou trier
            let request = FetchDescriptor<EntityFolderAccount>()
            entities = try validContext.fetch(request)
        } catch {
            print("Erreur lors de la récupération des données avec SwiftData")
        }
        return entities
    }
    
    // MARK: create account
    func create(nameAccount: String,
                nameImage: String,
                idName: String,
                idPrenom: String,
                numAccount: String ) -> EntityAccount {
        
        // Crée un nouvel objet EntityAccount
        let account            = EntityAccount()
        account.name           = nameAccount
        account.nameIcon      = nameImage
        account.dateEcheancier = Date().noon
        account.uuid           = UUID()
        
        // Crée une nouvelle identité et un compte initial pour cet EntityAccount
        let identity = IdentityManager.shared.create(name: idName, surName: idPrenom)
        identity.account = account
        account.identity = identity
        
        let initAccount     = InitAccountManager.shared.create(numAccount : numAccount, for: account)
        initAccount.account = account
        account.initAccount = initAccount
        
        // Ajoute le nouveau compte à la liste des entités
        validContext.insert(account)
        return account
    }
    
    func getRoot(modelContext: ModelContext) -> [EntityFolderAccount] {
        let request = FetchDescriptor<EntityFolderAccount>(predicate: #Predicate { $0.isRoot == false })
        let entities = try? validContext.fetch(request)
        return entities!
    }
    
    // Juste pour le debug
    func printAccount(entityAccount : EntityAccount, description : String) {
        let name     = entityAccount.name
        let identity = entityAccount.identity
        let idName   = identity?.name
        let idPrenom = identity?.surName
        let idNumber = entityAccount.initAccount?.codeAccount
        
        print("\(description)       : \(name) \(idName ?? "") \(idPrenom ?? "") \(idNumber ?? "")")
    }
}

class AccountViewModel: ObservableObject {
    
    @Published var items: [EntityAccount] = []
    @Published var isLoading: Bool = false
    
    private let manager = AccountManager()
    
    init() {
    }
    
    @Published var selectedAccount: EntityAccount? {
        didSet {
            load()
        }
    }
    
    @Published var modePayments: [EntityPaymentMode] = []
    
    func load() {
    }
    
    func add(name: String) {
    }
}

final class CurrrentAccountManager : ObservableObject {
    
    static let shared = CurrrentAccountManager()
    
    // Déclaration d'une variable globale pour toutes les fonctions
    @Published var currentAccount: EntityAccount?
    
    // Affectation d'un compte à la variable globale
    func setAccount(_ account: EntityAccount) {
        currentAccount = account
    }
    // Recupération d'un compte
    func getAccount()->EntityAccount? {
        return currentAccount
    }

    func fetchDataForCurrentAccount() {
        guard let account = currentAccount else {
            print("No account selected.")
            return
        }
        print("Traitement des données pour le compte \(account.name)")
    }
    
    // Réinitialisation de la variable globale
   func resetCurrentAccount() {
        currentAccount = nil
    }
}


