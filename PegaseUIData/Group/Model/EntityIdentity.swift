//
//  EntityIdentity.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import SwiftUI
import SwiftData

// MARK: - Identite

@Model
public class EntityIdentity {
    var adress     : String  = ""
    var complement : String  = ""
    var country    : String  = ""
    var cp         : Int32?  = 0
    var email      : String  = ""
    var mobile     : String  = ""
    var name       : String  = ""
    var nameImage  : String  = ""
    var phone      : String  = ""
    var surName    : String  = ""
    var town       : String  = ""
    
    var account    : EntityAccount?
    
    public init(adress: String,
                complement : String,
                country: String,
                cp: Int32,
                email: String,
                mobile: String,
                name: String,
                nameImage : String,
                phone: String,
                surName: String,
                town: String) {
        self.adress = adress
        self.complement = complement
        self.country = country
        self.cp = cp
        self.email = email
        self.mobile = mobile
        self.name = name
        self.nameImage = nameImage
        self.phone = phone
        self.surName = surName
        self.town = town
    }
    
    public init(name: String, surName: String) {
        self.name = name
        self.surName = surName
    }
    
    init() {
        
    }
}

// ObservableObject
final class IdentityManager  {
    
    // Contexte pour les modifications
    @Environment(\.modelContext) private var modelContext: ModelContext
    var currentAccount: EntityAccount?

    static let shared = IdentityManager()
    
    private var entities = [EntityIdentity]()
    
//    init() {
//    }
    
    func create(name: String = "", surName: String = "") -> EntityIdentity {
        let entity = EntityIdentity(name: name, surName: surName)
        entity.account = currentAccount
        
        // Ajout de l'entité au contexte
        modelContext.insert(entity)
        return entity
    }
    
    @discardableResult func getAllDatas() -> EntityIdentity {
        // Filtre pour l'entité liée à `currentAccount`
        
        let lhs = currentAccount!.uuid.uuidString
        let predicate = #Predicate<EntityIdentity>{ entity in entity.account!.uuid.uuidString == lhs }

        do {
            // Utilisation de SwiftData pour récupérer les entités correspondantes
            let fetchDescriptor = FetchDescriptor<EntityIdentity>(
                predicate: predicate)
            entities = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Erreur lors de la récupération des données")
        }
        
        // Retourne la première entité ou en crée une nouvelle si aucune n'existe
        return entities.first ?? create()
    }
}
