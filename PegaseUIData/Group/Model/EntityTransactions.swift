//
//  EntityTransactions.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityTransactions {
    var createAt: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    var updatedAt: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)

    var dateOperation: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)
    var datePointage: Date? = Date(timeIntervalSinceReferenceDate: 526815360.000000)

    var amount: Double = 0.0
    var bankStatement: Double = 0.0
    var checkNumber: String = ""
    
    @Attribute(.ephemeral) var sectionIdentifier: String?
    @Attribute(.ephemeral) var sectionYear: String?
    @Attribute(.ephemeral) var solde: Double? = 0.0
    
    var statut: Int16? = 0

    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount?
    var paymentMode: EntityPaymentMode?
    var sousOperations: [EntitySousOperations]?
//    @Relationship(inverse: \EntityTransactions.operationLiee) var operationLiee: EntityTransactions?

    public init() {

    }
}

actor ListTransactionsCache {
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
        setupAutomaticCleanup()
    }
    
    // Configuration du nettoyage automatique
    private nonisolated func setupAutomaticCleanup() {
        Task {
            while true {
                await cleanup()
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


