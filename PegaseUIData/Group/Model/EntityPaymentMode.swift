//
//  EntityPaymentMode.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData


@Model public class EntityPaymentMode {
    
    var name: String = ""
    //    @Attribute(.transformable(by: "NSColorValueTransformer")) var color: NSObject? = nil
    
    var uuid: UUID = UUID()
    
    var account: EntityAccount?
    var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.paymentMode) var preference: EntityPreference?
    @Relationship(inverse: \EntityTransactions.paymentMode) var transactions: [EntityTransactions]?
    
    public init(name: String, account: EntityAccount? = nil) {
        //        public init(name: String, color: NSObject? = nil, account: EntityAccount? = nil) {
        self.name = name
        //        self.color = color
        self.account = account
    }
    
}

final class PaymentModeManager : NSObject {
    
    static let shared = PaymentModeManager()
    private var entitiesModePaiement = [EntityPaymentMode]()
    var currentAccount: EntityAccount?
    
    @Environment(\.modelContext) var modelContext
    
    func getAllDatas(for account: EntityAccount) -> [EntityPaymentMode] {
        
        // Utilisez SwiftData pour récupérer les données avec un filtre
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: #Predicate<EntityPaymentMode> { entity in
                entity.account == currentAccount
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching data with SwiftData")
            return []
        }
    }
    
    func create(account: EntityAccount, name: String, color: Color) -> EntityPaymentMode {
        
        // Créez une instance de `EntityPaymentMode` avec les paramètres fournis
        let entity = EntityPaymentMode(name: name, account: account)
        entity.uuid = UUID()
        //    entity.color = color
        
        // Ajoutez l'entité au contexte
        modelContext.insert(entity)
        
        // Enregistrez le contexte pour persister les changements
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde de l'entité : \(error)")
        }
        
        return entity
    }
    
    func defaultModePaiement() {
        // Vérifiez si `entitiesModePaiement` est vide et `currentAccount` est valide
        guard let currentAccount = currentAccount, entitiesModePaiement.isEmpty else { return }
        
        // Liste des noms et couleurs des méthodes de paiement
        let paymentModes = [
            (name: localizeString("PaymentMethod.Bank_Card"), color: Color.green),
            (name: localizeString("PaymentMethod.Check"), color: Color.yellow),
            (name: localizeString("PaymentMethod.Cash"), color: Color.blue),
            (name: localizeString("PaymentMethod.Prelevement"), color: Color.red),
            (name: localizeString("PaymentMethod.Discount"), color: Color.gray),
            (name: localizeString("PaymentMethod.RetraitEspeces"), color: Color.orange),
            (name: localizeString("PaymentMethod.Transfers"), color: Color.brown)
        ]
        
        // Création des entités de mode de paiement
        for paymentMode in paymentModes {
            entitiesModePaiement.append( create(account: currentAccount, name: paymentMode.name, color: paymentMode.color))
        }
        
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: #Predicate { entity in
                entity.account == currentAccount
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        // Récupération des entités `EntityPaymentMode` liées au compte actuel
        do {
            entitiesModePaiement = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }
}

