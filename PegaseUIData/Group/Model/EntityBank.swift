//
//  EntityBank.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

@Model public class EntityBank {
    var adress     : String  = ""
    var bank       : String  = ""
    var complement : String  = ""
    var country    : String  = ""
    var cp         : Int32?  = 0
    var email      : String  = ""
    var fonction   : String  = ""
    var mobile     : String  = ""
    var name       : String  = ""
    var phone      : String  = ""
    var town       : String  = ""
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }
    var account    : EntityAccount?

    init( account  : EntityAccount)  {
        self.account         = account
    }
}

@Model
class BanqueInfo {
    var nomBanque: String = ""
    var adresse: String = ""
    var complement: String = ""
    var codePostal: String = ""
    var ville: String = ""
    
    // Informations du contact
    var nomContact: String = ""
    var fonctionContact: String = ""
    var telephoneContact: String = ""
    var uuid: UUID = UUID()
    
    @Relationship(deleteRule: .cascade, inverse: \EntityAccount.bank)
    var account: EntityAccount?
    
    init(nomBanque: String, adresse: String, complement: String, codePostal: String, ville: String, nomContact: String, fonctionContact: String, telephoneContact: String) {
        self.nomBanque = nomBanque
        self.adresse = adresse
        self.complement = complement
        self.codePostal = codePostal
        self.ville = ville
        self.nomContact = nomContact
        self.fonctionContact = fonctionContact
        self.telephoneContact = telephoneContact
    }
    
    init( account: EntityAccount)  {
        self.account = account
    }
}

final class BankManager {
    
    static let shared = BankManager()
    var entitiesBank = [EntityBank]()

    init() { }

    func create(account: EntityAccount) -> EntityBank {

        let entity = EntityBank(account: account)
        entitiesBank.append(entity)
        return entity
    }
    
    @discardableResult
    func getAllData(account: EntityAccount) -> EntityBank {
        let results = entitiesBank.filter { $0.account == account }
        
        if let firstEntity = results.first {
            return firstEntity
        } else {
            return create(account: account)
        }
    }
}
