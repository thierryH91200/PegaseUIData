//
//  EntityPaymentMode.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData

@Model public class EntityPaymentMode: Identifiable , Hashable {
    
    var name: String = ""
    @Attribute(.transformable(by: ColorTransformer.self)) var color: NSColor
    
    @Relationship var account: EntityAccount?
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    init(name: String, color: NSColor, account: EntityAccount? = nil ) {
        self.name = name
        self.color = color
        self.account = account
    }

    // Implémentez `Hashable`
    public static func == (lhs: EntityPaymentMode, rhs: EntityPaymentMode) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

final class CacheEntry<T> {
    let data: T
    let timestamp: Date
    let expirationInterval: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationInterval
    }
    
    init(data: T, timestamp: Date, expirationInterval: TimeInterval) {
        self.data = data
        self.timestamp = timestamp
        self.expirationInterval = expirationInterval
    }
}


enum PaymentModeError: Error {
    case contextNotConfigured
    case accountNotFound
    case saveFailed
    case fetchFailed
}

//Gère les opérations CRUD (Create, Read, Update, Delete)
//Interagit directement avec SwiftData
//Contient la logique métier complexe
//Est un singleton (shared)
//Gère les données par défaut
final class PaymentModeManager {
    
    static let shared = PaymentModeManager()
    
    var entities = [EntityPaymentMode]()
    
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
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityPaymentMode? {
        guard let account = account else {
            throw PaymentModeError.accountNotFound
        }
                
        let newMode = EntityPaymentMode(name: name, color: color, account: account)
        validContext.insert(newMode)
        try save()
        return newMode
    }

    func update(entity: EntityPaymentMode, name: String, color: NSColor) {
        entity.name = name
        entity.color = color
        do {
            try save()
        } catch {
            print("Failed to save updates: \(error.localizedDescription)")
            // Ajoutez ici une gestion d'erreur supplémentaire si nécessaire
        }
    }

    func getAllDatas(for account: EntityAccount?) -> [EntityPaymentMode]? {
        
        guard let account = account else {
            return []

        }
        
//        guard let account = CurrentAccountManager.shared.getAccount() else {
//            print("Erreur : aucun compte courant trouvé.")
//            return []
//        }

        // Sinon, charger depuis SwiftData
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode> { entity in
            entity.account?.uuid == lhs
        }
        
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            let fetchedData = try validContext.fetch(fetchDescriptor)
            return fetchedData
        } catch {
            print("Error fetching data with SwiftData: \(error)")
            return []
        }
    }

    func findOrCreate(account: EntityAccount, name: String, color: Color, uuid: UUID) -> EntityPaymentMode {
        if let entity = find(account: account, name: name) {
            return entity
        } else {
            return try! create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))!
        }
    }
    
    func save () throws {
        
        do {
            try validContext.save()
        } catch {
            throw PaymentModeError.saveFailed
        }
    }

    func find( account: EntityAccount, name: String) -> EntityPaymentMode? {
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode> { $0.account?.uuid == lhs && $0.name == name }

        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate, // Filtrer par le compte
            sortBy: [SortDescriptor(\.name, order: .forward)] // Trier par le nom
        )

        do {
            let searchResults = try validContext.fetch(fetchDescriptor)
            let result = searchResults.isEmpty == false ? searchResults.first : nil
            return result
        } catch {
            print("Error with request: \(error)")
            return nil
        }
    }
    
    // MARK: - delete ModePaiement
    func delete(entity: EntityPaymentMode)
    {
        validContext.undoManager?.beginUndoGrouping()
        validContext.undoManager?.setActionName("Supprimer le mode de paiement")
        validContext.delete(entity)
        validContext.undoManager?.endUndoGrouping()

        do {
            try validContext.save()
        } catch {
            print("Erreur lors de la sauvegarde après suppression : \(error)")
        }
    }

    func defaultModePaiement(for account: EntityAccount) {
        entities.removeAll()
        
        // Liste des noms et couleurs des méthodes de paiement
        let names = [ String(localized :"Bank Card"),
                      String(localized :"Check"),
                      String(localized :"Cash"),
                      String(localized :"Bank withdrawal"),
                      String(localized :"Discount"),
                      String(localized :"Cash withdrawal"),
                      String(localized :"Transfers")]
        let paymentModes: [(name: String, color: NSColor)] = [
            ( names[0], .red),
            ( names[1], .green),
            ( names[2], .yellow),
            ( names[3], .blue),
            ( names[4], .red),
            ( names[5], .gray),
            ( names[6], .brown)
        ]
        
        // Création des entités de mode de paiement
        paymentModes.forEach {
           try!  _ = create(account: account, name: $0.name, color: $0.color)
        }
               
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account?.uuid == lhs }
                
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        // Récupération des entités EntityPaymentMode liées au compte actuel
        do {
            entities = try validContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }
}


// Fait le lien entre la Vue (UI) et le Manager
// Gère l'état de l'interface (@Published)
// Transforme les données pour l'affichage
// Ne contient que la logique liée à l'UI

class PaymentModeViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var modePayments: [EntityPaymentMode]
    private let manager = PaymentModeManager.shared
    @Published var isLoading: Bool = false

    init(account: EntityAccount) {
        self.account = account
        self.modePayments = []
        
        loadInitialData()
    }
    
    // MARK: Actions utilisateur :
    private func loadInitialData() {
        modePayments = manager.getAllDatas(for: account)!
    }

    func add(name: String, color: Color) {
        do {
            let _ = try manager.create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))
            reloadData()
        } catch PaymentModeError.accountNotFound {
            // Gérer l'erreur account non trouvé
            print("Erreur : compte non trouvé")
        } catch PaymentModeError.saveFailed {
            // Gérer l'erreur de sauvegarde
            print("Erreur : échec de la sauvegarde")
        } catch {
            // Gérer les autres erreurs
            print("Erreur inattendue : \(error)")
        }
    }

    func delete(at index: Int) {
        guard modePayments.indices.contains(index) else { return }
        let mode = modePayments[index]
        
        manager.delete(entity: mode) // Appelle la méthode sans try

        modePayments.remove(at: index)
        reloadData()      // Recharger depuis la base de données
    }
    
    
    // MARK: Communication avec les services ou les managers :
    @discardableResult
    func reloadData() -> [EntityPaymentMode] {
        modePayments = manager.getAllDatas(for: account)!
        return modePayments
    }
    
    func saveChanges() throws {
        try manager.save()
    }
}

