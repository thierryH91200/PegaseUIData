//
//  EntityPaymentMode.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData


@Model
public class EntityPaymentMode {
    
    var name: String = ""
    @Attribute(.transformable(by: ColorTransformer.self)) var color: Color
    var uuid: UUID = UUID()
    
    var account: EntityAccount?
    var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.paymentMode) var preference: EntityPreference?
    @Relationship(inverse: \EntityTransactions.paymentMode) var transactions: [EntityTransactions]?
    
    init(name: String, color: Color, account: EntityAccount? = nil) {
        self.name = name
        self.color = color
        self.uuid = uuid
        
        self.account = account
    }
}

final class PaymentModeManager : NSObject {
    
    static let shared = PaymentModeManager()
    
    var currentAccount: EntityAccount?
    var entities = [EntityPaymentMode]()
    
    // Contexte pour les modifications
    var modelContext : ModelContext?
    
    func getAllDatas(for account: EntityAccount?, context: ModelContext?) -> [EntityPaymentMode] {
        
        guard let modelContext1 = context else { return [] }
        modelContext = modelContext1
        
        currentAccount = CurrrentAccountManager.shared.getAccount()
        
        guard let account = currentAccount else { return [] }
        
        // Utilisez SwiftData pour récupérer les données avec un filtre
        let lhs = account.uuid.uuidString
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account!.uuid.uuidString == lhs }

        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            entities = try modelContext!.fetch(fetchDescriptor)
        } catch {
            print("Error fetching data with SwiftData")
            entities =  []
        }
        for entity in entities {
            print("\(entity.name)")
        }
        return entities
    }
    
    func findOrCreate ( account: EntityAccount,  name: String, color: Color, uuid: UUID) -> EntityPaymentMode {
        
        var entity = find( account: account, name: name )
        if entity == nil {
            entity = create(account: currentAccount!, name: name, color: color)
        }
        return entity!
    }

    func create(account: EntityAccount, name: String, color: Color) -> EntityPaymentMode {
        
        // Créez une instance de `EntityPaymentMode` avec les paramètres fournis
        let entity = EntityPaymentMode(name: name, color: color, account: account)
        
        // Ajoutez l'entité au contexte
        modelContext!.insert(entity)
        
        // Enregistrez le contexte pour persister les changements
        do {
            try modelContext!.save()
        } catch {
            print("Erreur lors de la sauvegarde de l'entité : \(error)")
        }
        
        return entity
    }
    
    func find( account: EntityAccount, name: String) -> EntityPaymentMode? {
        
        let lhs = currentAccount!.uuid.uuidString
        let predicate = #Predicate<EntityPaymentMode> { $0.account?.uuid.uuidString == lhs && $0.name == name }

        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate, // Filtrer par le compte
            sortBy: [SortDescriptor(\.name, order: .forward)] // Trier par le nom
        )

        do {
            let searchResults = try modelContext!.fetch(fetchDescriptor)
            let result = searchResults.isEmpty == false ? searchResults.first : nil
            return result
        } catch {
            print("Error with request: \(error)")
            return nil
        }
    }
    
    // MARK: - delete ModePaiement
    func remove(entity: EntityPaymentMode)
    {
        modelContext!.undoManager?.beginUndoGrouping()
        modelContext!.undoManager?.setActionName("DeletePaymentMode")
        modelContext!.delete(entity)
        modelContext!.undoManager?.endUndoGrouping()
    }

    func defaultModePaiement(for account: EntityAccount, context: ModelContext?) {
        // Vérifiez si `entitiesModePaiement` est vide et `currentAccount` est valide
        guard let modelContext1 = context else { return }
        modelContext = modelContext1

        guard entities.isEmpty else { return }
        
        // Liste des noms et couleurs des méthodes de paiement
        let paymentModes = [
            (name : String(localized:"Bank Card"), color : Color.green),
            (name : String(localized:"Check"), color : Color.yellow),
            (name : String(localized:"Cash"), color : Color.blue),
            (name : String(localized:"Bank withdrawal"), color : Color.red),
            (name : String(localized:"Discount"), color : Color.gray),
            (name : String(localized:"Cash withdrawal"), color : Color.orange),
            (name : String(localized:"Transfers"), color : Color.brown)
        ]
       
        // Création des entités de mode de paiement
        for paymentMode in paymentModes {
            _ = create(account: account, name: paymentMode.name, color: paymentMode.color)
        }
        
        let lhs = account.uuid.uuidString
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account!.uuid.uuidString == lhs }
                
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        // Récupération des entités `EntityPaymentMode` liées au compte actuel
        do {
            entities = try modelContext!.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }
}

