//
//  EntityInitAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model public class EntityInitAccount {
    var bic: String = ""
    var cleRib: String = ""
    var codeAccount: String = ""
    var codeBank: String = ""
    var codeGuichet: String = ""
    
    var iban: String = ""
//    var iban2: String = ""
//    var iban3: String = ""
//    var iban4: String = ""
//    var iban5: String = ""
//    var iban6: String = ""
//    var iban7: String = ""
//    var iban8: String = ""
//    var iban9: String = ""

    var engage: Double = 0.0
    var prevu: Double = 0.0
    var realise: Double = 0.0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount
 
    public init() {
        self.iban = "FR76"
        self.account = CurrentAccountManager.shared.getAccount()!
    }
}

enum EnumError: Error {
    case contextNotConfigured
    case accountNotFound
    case saveFailed
    case fetchFailed
}

final class InitAccountManager {
    
    static let shared = InitAccountManager()
    private var initAccounts = [EntityInitAccount]()
    private var initAccount : EntityInitAccount?

    var account: EntityAccount?
    
    // Contexte pour les modifications
    var modelContext : ModelContext?
    var validContext: ModelContext {
        guard let context = modelContext else {
            print("File: \(#file), Function: \(#function), line: \(#line)")
            fatalError("ModelContext non configuré. Veuillez appeler configure.")
        }
        return context
    }

    init() {
    }

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // Utiliser un seul contexte pour la gestion des données
    func getAllDatas() -> EntityInitAccount? {
        
        guard let account = CurrentAccountManager.shared.getAccount() else {
            print("Erreur : aucun compte courant trouvé.")
            return nil
        }

        let lhs = account.uuid
        let predicate = #Predicate<EntityInitAccount>{ entity in entity.account.uuid == lhs }

        let descriptor = FetchDescriptor<EntityInitAccount>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.codeAccount)]
        )

        do {
            initAccounts = try validContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        
        if let firstEntity = initAccounts.first {
            return firstEntity
        } else {
            do {
                return try create(numAccount: "", for: account)
            } catch {
                print("Erreur lors de la création d'une entité : \(error)")
                fatalError("Impossible de créer une entité, vérifiez la logique de gestion des erreurs.")
            }
        }
    }

    // Méthode de création d'entité
    func create(numAccount: String = "", for account: EntityAccount) throws -> EntityInitAccount {
        let entity = EntityInitAccount()
        entity.bic = ""
        entity.cleRib = ""
        entity.codeBank = ""
        entity.codeAccount = numAccount
        entity.codeGuichet = ""
        entity.engage = 0
        entity.iban = ""

        entity.prevu = 0
        entity.realise = 0
        entity.account = account // Associe le compte à l'entité
        validContext.insert(entity)
        initAccounts.append(entity) // Mise à jour de la liste locale
        
        return entity
    }
    
    func delete(entityInitAccount: EntityInitAccount) {
        
        validContext.delete( entityInitAccount) // Appelle la méthode sans try
        initAccount = nil
 
        initAccount = getAllDatas()      // Recharger depuis la base de données
    }
    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw PaymentModeError.saveFailed
        }
    }
}

class InitAccountViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var initAccount: EntityInitAccount?
    private let manager = InitAccountManager()

    init(account: EntityAccount) {
        self.account = account
        self.initAccount = nil
        
        loadInitialData()
    }
    
    // MARK: Actions utilisateur :
    private func loadInitialData() {
        initAccount = manager.getAllDatas()
    }

    func add(name: String) {
        do {
            let _ = try manager.create(for: account)
            reloadData()
        } catch EnumError.accountNotFound {
            // Gérer l'erreur account non trouvé
            print("Erreur : compte non trouvé")
        } catch EnumError.saveFailed {
            // Gérer l'erreur de sauvegarde
            print("Erreur : échec de la sauvegarde")
        } catch {
            // Gérer les autres erreurs
            print("Erreur inattendue : \(error)")
        }
    }

    func delete(entity: EntityInitAccount) {
        
        manager.delete(entityInitAccount: entity)
        initAccount = nil
        reloadData()      // Recharger depuis la base de données
    }
    
    // MARK: Communication avec les services ou les managers :
    @discardableResult
    func reloadData() -> EntityInitAccount {
        let initAccounts = manager.getAllDatas()
        return initAccounts!
    }
    
    func saveChanges() throws {
        try manager.save()
    }
}

