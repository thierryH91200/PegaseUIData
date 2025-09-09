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
import Combine


@Model class EntityAccount: Identifiable {

    var name: String = ""
    var nameIcon: String = ""
    var currencyCode : String = "EUR"
    var dateEcheancier: Date = Date().noon
    var isDemo : Bool = false
    var isAccount : Bool = true

    //    @Attribute(.ephemeral) var solde: Double? = 0.0

    @Relationship(deleteRule: .cascade, inverse: \EntitySchedule.account)
    var echeanciers: [EntitySchedule]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityIdentity.account)
    var identity: EntityIdentity?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityBanqueInfo.account)
    var bank: EntityBanqueInfo?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityPreference.account)
    var preference: EntityPreference?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityInitAccount.account)
    var initAccount: EntityInitAccount?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityPaymentMode.account)
    var paymentMode: [EntityPaymentMode]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityStatus.account)
    var status: [EntityStatus]?

    @Relationship(deleteRule: .cascade, inverse: \EntityBankStatement.account)
    var bankStatement: [EntityBankStatement]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityRubric.account)
    var rubric: [EntityRubric]?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityCheckBook.account)
    var carnetCheques: [EntityCheckBook]?

    var compteLie: EntityTransaction?
    
    @Relationship(deleteRule: .cascade, inverse: \EntityTransaction.account)
    var transactions: [EntityTransaction]?

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init() {
    }
    
    public init(name: String, nameIcon: String) {
        self.name = name
        self.nameIcon = nameIcon
    }
}

extension EntityAccount: Equatable {
    static func == (lhs: EntityAccount, rhs: EntityAccount) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension EntityAccount {
    @Transient
    @MainActor
    var solde: Double
    {
        guard isAccount == true else { return 0.0 }
        
        var balance = 0.0
        if let transactions = transactions {
            for transaction in transactions {
                balance += transaction.amount
            }
        }
        return balance
    }
}

final class AccountManager {
      
    static let shared = AccountManager()
    var entities = [EntityAccount]()
    
    var modelContext: ModelContext? {
        DataContext.shared.context
    }
    
    init() { }
        
    // MARK: create account
    @MainActor func create(nameAccount: String,
                nameImage: String,
                idName: String,
                idPrenom: String,
                numAccount: String ) -> EntityAccount? {
        
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
        
        do {
            let initAccount = try InitAccountManager.shared.create(numAccount: numAccount, for: account)
            initAccount.account = account
            account.initAccount = initAccount
        } catch {
            // Gère les erreurs lors de la création du compte initial
            printTag("Failed to create InitAccount: \(error.localizedDescription)")
            return nil
        }
        
        // Ajoute le nouveau compte à la liste des entités
        modelContext?.insert(account)
        save()
        return account
    }
    
    //  6F9B6677-C4B6-4C8C-9228-67C80641D0DE
    //  179E047F-1B09-4BA9-BCA1-A87858B4A08E
    //  919D07FD-2D35-499E-8B21-1E99E00240E5
    //  A8F3ADA5-B531-4263-9222-AF16E1C067BB    
    @MainActor
    func getAccount(uuid: UUID) -> EntityAccount? {
        guard let ctx = modelContext else {
            printTag("getAccount(uuid:): ModelContext indisponible")
            return nil
        }
        getAllData()
        let predicate = #Predicate<EntityAccount> { $0.uuid == uuid }
        var descriptor = FetchDescriptor<EntityAccount>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            printTag(uuid.uuidString)
            let entity = try ctx.fetch(descriptor).first
            return entity
        } catch {
            printTag("Erreur lors de la récupération des données : \(error.localizedDescription)")
            return nil
        }
    }

    func getAllData() -> [EntityAccount] {
        do {
            // Exécution d'une requête manuelle si besoin de filtrer ou trier
            let request = FetchDescriptor<EntityAccount>()
            entities = try modelContext?.fetch(request) ?? []
            for entity in entities {
                printAccount(entityAccount: entity, description: "Account \(entity.uuid.uuidString)")
            }
        } catch {
            printTag("Erreur lors de la récupération des données avec SwiftData")
        }
        return entities
    }
    
//    func getRoot(modelContext: ModelContext) -> [EntityFolderAccount] {
//        let request = FetchDescriptor<EntityFolderAccount>(predicate: #Predicate { $0.isRoot == false })
//        let entities = try? modelContext.fetch(request)
//        return entities!
//    }
    
    // Juste pour le debug
    func printAccount(entityAccount : EntityAccount, description : String) {
        let name     = entityAccount.name
        let identity = entityAccount.identity
        let idName   = identity?.name
        let idSurname = identity?.surName
        let idNumber = entityAccount.initAccount?.codeAccount
        let id = entityAccount.uuid

        printTag("\(description)       : \(id) \(name) \(idName ?? "") \(idSurname ?? "") \(idNumber ?? "")")
    }
    
    func save() {
        do {
            try modelContext?.save()
        } catch {
            print(EnumError.saveFailed)
        }
    }
}

@MainActor
final class CurrentAccountManager: ObservableObject {
    
    static let shared = CurrentAccountManager()
    
    // UUID stocké en String pour compatibilité avec AppStorage/UI
    @Published var currentAccountID: String

    // Propriété calculée pratique pour accéder directement à l'objet
    var currentAccount: EntityAccount? {
        getAccount()
    }

    private init() {
        self.currentAccountID = ""
    }

    // Affectation d'un compte à la variable globale
    // Retourne true si l'ID est valide et correspond à un compte existant.
    @discardableResult
    func setAccount(_ id: String) -> Bool {
        guard let uuid = UUID(uuidString: id) else {
            printTag("setAccount: ID invalide \(id)")
            return false
        }
        if let account = AccountManager.shared.getAccount(uuid: uuid) {
            self.currentAccountID = account.uuid.uuidString
            printTag("setAccount OK", category: account.uuid.uuidString)
            return true
        } else {
            let account = AccountManager.shared.getAllData()
            printTag("setAccount: aucun compte trouvé pour \(id)")
            return false
        }
    }
    
    // Récupération d'un compte
    func getAccount() -> EntityAccount? {
        guard let uuid = UUID(uuidString: currentAccountID) else {
            return nil
        }
        guard let account = AccountManager.shared.getAccount(uuid: uuid) else {
            return nil
        }
        printTag("getAccount", category: account.uuid.uuidString)
        return account
    }
    
    // Réinitialiser le compte courant
    func clearAccount() {
        self.currentAccountID = ""
        printTag("clearAccount")
    }
    

}

//extension EntityTransaction {
//    func asChartEntry() -> ChartDataEntry {
//        ChartDataEntry(x: dateOperation.timeIntervalSince1970,
//                       y: amount)
//    }
//}

