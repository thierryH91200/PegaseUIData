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

    var createAt:  Date? = Date()
    var updatedAt: Date? = Date()

    var dateOperation: Date? = Date()
    var datePointage:  Date? = Date()

    var bankStatement: Double = 0.0
    var checkNumber: String = ""
    
    var status: EntityStatus?
    var paymentMode: EntityPaymentMode?
    
//    @Relationship(deleteRule: .cascade, inverse: \EntitySousOperations.transaction)
//    var sousOperations: [EntitySousOperations]? = []
    var sousOperations: [EntitySousOperations] = []

    var amount: Double {
        sousOperations.reduce(0.0) { $0 + $1.amount }
    }

    @Attribute(.ephemeral) var solde: Double? = 0.0
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount
    
//    @Relationship(inverse: \EntityTransactions.operationLiee)
//    var operationLiee: EntityTransactions?
    
    private var _sectionIdentifier: String?

    
    /// Propriété calculée pour obtenir l'identifiant de section complet (année * 100 + mois).
    var sectionIdentifier: String? {
        guard let date = datePointage else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        if let year = components.year, let month = components.month {
            return String(format: "%ld", year * 100 + month)
        }
        return nil
    }
    
    /// Propriété calculée pour obtenir uniquement l'année de la date de pointage.
    var sectionYear: String? {
        guard let date = datePointage else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        if let year = components.year {
            return String(format: "%ld", year)
        }
        return nil
    }

    public init() {
        let account = CurrentAccountManager.shared.getAccount() 
        self.account = account!
    }
    
    init(datePointage: Date?, dateOperation: Date?, libelle: String, category: String, paymentMode: String, amount: Double) {
        self.datePointage = datePointage
        self.dateOperation = dateOperation
//        self.libelle = libelle
//        self.category = category
//        self.amount = amount
        self.account = CurrentAccountManager.shared.getAccount()!

        self.paymentMode = EntityPaymentMode(name: paymentMode, color: .black, account: account)
    }

}

extension EntityTransactions {
    func addSubOperation(_ subOperation: EntitySousOperations) {
        subOperation.transaction = self
        self.sousOperations.append(subOperation)
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


