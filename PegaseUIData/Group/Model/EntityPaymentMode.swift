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
    
    init(name: String = "Test", color: NSColor = .black ) {
        guard let account = CurrentAccountManager.shared.getAccount() else {
            fatalError("Aucun compte disponible pour créer un mode de paiement")
        }

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

protocol PaymentModeManaging {
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityPaymentMode?
    func update(entity: EntityPaymentMode, name: String, color: NSColor)
    func getAllData() -> [EntityPaymentMode]?
    func getAllNames(for account: EntityAccount) -> [String]
    func findOrCreate(account: EntityAccount, name: String, color: Color, uuid: UUID) -> EntityPaymentMode
    func find( account: EntityAccount?, name: String) -> EntityPaymentMode?
    func delete(entity: EntityPaymentMode)
    func createDefaultPaymentModes(for account: EntityAccount)

    func save () throws

}

//Gère les opérations CRUD (Create, Read, Update, Delete)
//Interagit directement avec SwiftData
//Contient la logique métier complexe
//Est un singleton (shared)
//Gère les données par défaut
final class PaymentModeManager : PaymentModeManaging {
    
    static let shared = PaymentModeManager()
    
    var entities = [EntityPaymentMode]()
    var modelContext: ModelContext? {
        DataContext.shared.context
    }

    init() { }
    
    func create(account: EntityAccount?, name: String, color: NSColor) throws -> EntityPaymentMode? {
                
        let mode = EntityPaymentMode(name: name, color: color)
        modelContext?.insert(mode)
        try save()
        return mode
    }

    func update(entity: EntityPaymentMode, name: String, color: NSColor) {
        entity.name = name
        entity.color = color
        do {
            try save()
        } catch {
            printTag("Failed to save updates: \(error.localizedDescription)")
        }
    }

    func getAllData() -> [EntityPaymentMode]? {
                
        let account = CurrentAccountManager.shared.getAccount()
        guard account != nil else {
            return []
        }

        let lhs = account!.uuid
        let predicate = #Predicate<EntityPaymentMode> { entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)]
        
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: sort )
        
        do {
            let fetchedData = try modelContext?.fetch(fetchDescriptor) ?? []
            return fetchedData
        } catch {
            printTag("Error fetching data with SwiftData: \(error)")
            return []
        }
    }
    
    // MARK: getAllNames ModePaiement
    func getAllNames(for account: EntityAccount) -> [String] {
        
         return getAllData()?.map { $0.name } ?? []
    }

    // MARK: findOrCreate ModePaiement
   func findOrCreate(account: EntityAccount, name: String, color: Color, uuid: UUID) -> EntityPaymentMode {
        if let entity = find(account: account, name: name) {
            return entity
        } else {
            return try! create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))!
        }
    }
    
    // MARK: find ModePaiement
    func find( account: EntityAccount? = nil, name: String) -> EntityPaymentMode? {
        
        guard let account = account ?? CurrentAccountManager.shared.getAccount() else {
            printTag("Aucun compte disponible pour la recherche.")
            return nil
        }
        
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode> { $0.account.uuid == lhs && $0.name == name }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)] // Trier par le nom

        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate, // Filtrer par le compte
            sortBy: sort )

        do {
            let searchResults = try modelContext?.fetch(fetchDescriptor) ?? []
            let result = searchResults.isEmpty == false ? searchResults.first : nil
            return result
        } catch {
            printTag("Error with request: \(error)")
            return nil
        }
    }
    
    // MARK: delete ModePaiement
    func delete(entity: EntityPaymentMode)
    {
        modelContext?.undoManager?.beginUndoGrouping()
        modelContext?.undoManager?.setActionName("Delete the modePayment")
        modelContext?.delete(entity)
        modelContext?.undoManager?.endUndoGrouping()

        do {
            try modelContext?.save()
        } catch {
            printTag("Erreur lors de la sauvegarde après suppression : \(error)")
        }
    }

    // MARK: default ModePaiement
    func createDefaultPaymentModes(for account: EntityAccount) {
        entities.removeAll()
        
        // Liste des noms et couleurs des méthodes de paiement
        let names = [ String(localized :"Bank Card"),
                      String(localized :"Check"),
                      String(localized :"Cash"),
                      String(localized :"Bank withdrawal"),
                      String(localized :"Discount"),
                      String(localized :"Cash withdrawal"),
                      String(localized :"Bank transfer"),
                      String(localized :"Direct debit")]
        let paymentModes: [(name: String, color: NSColor)] = [
            ( names[0], .red),
            ( names[1], .green),
            ( names[2], .yellow),
            ( names[3], .blue),
            ( names[4], .red),
            ( names[5], .gray),
            ( names[6], .brown),
            ( names[7], .black)
        ]
        
        // Création des entités de mode de paiement
        paymentModes.forEach {
            do {
                try _ = create(account: account, name: $0.name, color: $0.color)
            } catch {
                printTag("Erreur création par défaut : \(error)")
            }
        }
               
        let lhs = account.uuid
        let predicate = #Predicate<EntityPaymentMode>{ entity in entity.account.uuid == lhs }
        let sort = [SortDescriptor(\EntityPaymentMode.name, order: .forward)]
                
        let fetchDescriptor = FetchDescriptor<EntityPaymentMode>(
            predicate: predicate,
            sortBy: sort )
        
        // Récupération des entités EntityPaymentMode liées au compte actuel
        do {
            entities = try modelContext?.fetch(fetchDescriptor) ?? []
        } catch {
            printTag("Erreur lors de la récupération des modes de paiement : \(error.localizedDescription)")
        }
    }
    
    // MARK: save ModePaiement
    func save () throws {
        
        do {
            try modelContext?.save()
        } catch {
            throw EnumError.saveFailed
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
        modePayments = manager.getAllData()!
    }

    func add(name: String, color: Color) {
        do {
            let _ = try manager.create(account: account, name: name, color: NSColor.fromSwiftUIColor(color))
            loadInitialData()
        } catch EnumError.accountNotFound {
            // Gérer l'erreur account non trouvé
            printTag("Erreur : compte non trouvé")
        } catch EnumError.saveFailed {
            // Gérer l'erreur de sauvegarde
            printTag("Erreur : échec de la sauvegarde")
        } catch {
            // Gérer les autres erreurs
            printTag("Erreur inattendue : \(error)")
        }
    }

//    func delete(at index: Int) {
//        guard modePayments.indices.contains(index) else { return }
//        let mode = modePayments[index]
//        
//        manager.delete(entity: mode) // Appelle la méthode sans try
//
//        modePayments.remove(at: index)
//        loadInitialData()      // Recharger depuis la base de données
//    }
    
    // MARK: Communication avec les services ou les managers :
//    @discardableResult
//    func reloadData() -> [EntityPaymentMode] {
//        modePayments = manager.getAllData()!
//        return modePayments
//    }
    
    func saveChanges() throws {
        try manager.save()
    }
}
