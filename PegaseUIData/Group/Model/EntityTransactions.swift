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

    var createAt:  Date = Date()
    var updatedAt: Date = Date()

    var dateOperation: Date = Date()
    var datePointage:  Date = Date()

    var bankStatement: Double = 0.0
    var checkNumber: String = ""
    
    var status: EntityStatus?
    var paymentMode: EntityPaymentMode?
    
    @Relationship(deleteRule: .cascade, inverse: \EntitySousOperations.transaction)
    var sousOperations: [EntitySousOperations] = []

//    private(set) var amount: Double = 0.0

    @Attribute(.ephemeral) var solde: Double? = 0.0
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount
    
//    @Relationship(inverse: \EntityTransactions.operationLiee)
//    var operationLiee: EntityTransactions?
    
    private var _sectionIdentifier: String?

    
    /// Propriété calculée pour obtenir l'identifiant de section complet (année * 100 + mois).
    var sectionIdentifier: String? {
        let date = datePointage
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        if let year = components.year, let month = components.month {
            return String(format: "%ld", year * 100 + month)
        }
        return nil
    }
    
    /// Propriété calculée pour obtenir uniquement l'année de la date de pointage.
    var sectionYear: String? {
        let date = datePointage
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        if let year = components.year {
            return String(format: "%ld", year)
        }
        return nil
    }

    public init() {
        
        self.createAt = Date().noon
        self.updatedAt = Date().noon

        if let account = CurrentAccountManager.shared.getAccount() {
            self.account = account
        } else {
            fatalError("Impossible de récupérer le compte courant.")
        }
    }
    
//    func updateAmount() {
//        amount = sousOperations.reduce(0.0) { $0 + $1.amount }
//    }
}

extension EntityTransactions {
    func addSubOperation(_ subOperation: EntitySousOperations) {
        
        guard !sousOperations.contains(where: { $0.id == subOperation.id }) else {
            return // Ne pas ajouter si elle existe déjà
        }
        subOperation.transaction = self
        sousOperations.append(subOperation)
//        updateAmount() // Recalculer le montant
    }
}

extension EntityTransactions {
    var dateOperationString: String {
        return dateOperation.formatted()
    }
    
    var datePointageString: String {
        datePointage.formatted()
    }
    
    var bankStatementString: String {
        String(format: "%.2f", bankStatement)
    }
    
    var statusString: String {
        status.map { "\($0.name)" } ?? "N/A"
    }
    
    var paymentModeString: String {
        paymentMode.map { "\($0.name)" } ?? "N/A"
    }
    
    var amountString: String {
        let price = formatPrice(amount)
        return price
    }

    var amount: Double {
            sousOperations.reduce(0.0) { $0 + $1.amount }
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


