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
    @Relationship var account: EntityAccount
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    
    init(name: String, color: NSColor, account: EntityAccount? = nil ) {
        self.name = name
        self.color = color
        self.account = account!
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

actor PaymentModeCache {
    // Configuration du cache
    private struct Config {
        static let defaultExpirationInterval: TimeInterval = 5 * 60 // 5 minutes
        static let maxCacheSize = 50 // Maximum d'entrées dans le cache
        static let cleanupInterval: TimeInterval = 60 // Nettoyage toutes les minutes
    }
    
    // Le cache principal utilisant NSCache pour la gestion automatique de la mémoire
    private var cache = NSCache<NSString, CacheEntry<[EntityPaymentMode]>>()
    private var lastCleanupTime = Date()
    
    init() {
        cache.countLimit = Config.maxCacheSize
        Task { @MainActor in
            setupAutomaticCleanup()
        }
    }
    
    // Configuration du nettoyage automatique
    @MainActor
    private func setupAutomaticCleanup() {
        Task {
            while true {
                await cleanup() // Add 'try?' since cleanup() is likely throwing
                try? await Task.sleep(nanoseconds: UInt64(Config.cleanupInterval * 1_000_000_000))
            }
        }
    }
    
    // Stockage dans le cache
    func store(key: UUID, data: [EntityPaymentMode], expirationInterval: TimeInterval = Config.defaultExpirationInterval) {
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            expirationInterval: expirationInterval
        )
        cache.setObject(entry, forKey: key.uuidString as NSString)
    }
    
    // Récupération depuis le cache
    func retrieve(key: UUID) -> [EntityPaymentMode]? {
        guard let entry = cache.object(forKey: key.uuidString as NSString) else {
            return nil
        }
        
        // Vérifier si l'entrée est expirée
        if entry.isExpired {
            cache.removeObject(forKey: key.uuidString as NSString)
            return nil
        }
        
        return entry.data
    }
    
    // Invalidation d'une entrée spécifique
    func invalidate(key: UUID) {
        cache.removeObject(forKey: key.uuidString as NSString)
    }
    
    // Nettoyage complet du cache
    func invalidateAll() {
        cache.removeAllObjects()
    }
    
    // Nettoyage automatique des entrées expirées
    private func cleanup() {
        let now = Date()
        if now.timeIntervalSince(lastCleanupTime) < Config.cleanupInterval {
            return
        }
        
        // Parcourir et nettoyer les entrées expirées
        // Note: Cette implémentation est simplifiée car NSCache ne permet pas
        // d'itérer sur ses éléments directement
        lastCleanupTime = now
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
    private var cache: PaymentModeCache = PaymentModeCache()
    
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

    func getAllDatas(for account: EntityAccount, useCache: Bool = true) async -> [EntityPaymentMode] {
        let accountId = account.uuid
        
        // Vérifier le cache si demandé
        if useCache, let cachedData = await cache.retrieve(key: accountId) {
            return cachedData
        }
        
        // Sinon, charger depuis SwiftData
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode> { entity in
            entity.account.uuid == lhs
        }
        
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            let fetchedData = try validContext.fetch(fetchDescriptor)
            // Mettre en cache les nouvelles données
            await cache.store(key: accountId, data: fetchedData)
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
        let predicate = #Predicate<EntityPaymentMode> { $0.account.uuid == lhs && $0.name == name }

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
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account.uuid == lhs }
                
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
    
    func clearCache(for account: EntityAccount) async {
        await cache.invalidate(key: account.uuid)
    }
    
    func clearAllCache() async {
        await cache.invalidateAll()
    }
}


// Fait le lien entre la Vue (UI) et le Manager
// Gère l'état de l'interface (@Published)
// Transforme les données pour l'affichage
// Ne contient que la logique liée à l'UI

class PaymentModeViewModel: ObservableObject {
    @Published var account: EntityAccount
    @Published var modePayments: [EntityPaymentMode]
    private let manager = PaymentModeManager()
    @Published var isLoading: Bool = false

    
    init(account: EntityAccount) {
        self.account = account
        self.modePayments = []
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: Actions utilisateur :
    @MainActor
    private func loadInitialData() async {
        modePayments = await manager.getAllDatas(for: account)
    }

    @MainActor
    func add(name: String, color: Color) async {
        do {
            let newMode = try manager.create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))
            await manager.clearCache(for: account)
            await reloadData()
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

    func delete(at index: Int) async {
        guard modePayments.indices.contains(index) else { return }
        let mode = modePayments[index]
        
        manager.delete(entity: mode) // Appelle la méthode sans try
        await manager.clearCache(for: account) // Vider le cache après suppression

        modePayments.remove(at: index)
        await reloadData(useCache: false)      // Recharger depuis la base de données
    }
    
    
    // MARK: Communication avec les services ou les managers :
    @discardableResult
    func reloadData(useCache: Bool = true) async -> [EntityPaymentMode] {
        modePayments = await manager.getAllDatas(for: account, useCache: useCache)
        return modePayments
    }
    
    func saveChanges() throws {
        try manager.save()
    }

}

