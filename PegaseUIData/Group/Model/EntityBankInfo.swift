//
//  EntityBankInfo.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/01/2025.
//

import Foundation
import SwiftData


@Model
class EntityBanqueInfo : Identifiable {
    var nomBanque: String = ""
    var adresse: String = ""
    var complement: String = ""
    var codePostal: String = ""
    var ville: String = ""
    
    // Informations du contact
    var nomContact: String = ""
    var fonctionContact: String = ""
    var telephoneContact: String = ""
    
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    var account: EntityAccount?
    
    init(nomBanque: String,
         adresse: String,
         complement: String,
         codePostal: String,
         ville: String,
         nomContact: String,
         fonctionContact: String,
         telephoneContact: String) {
        self.nomBanque = nomBanque
        self.adresse = adresse
        self.complement = complement
        self.codePostal = codePostal
        self.ville = ville
        
        self.nomContact = nomContact
        self.fonctionContact = fonctionContact
        self.telephoneContact = telephoneContact
        
        self.account = CurrrentAccountManager.shared.getAccount()!
    }
    
    init( account: EntityAccount)  {
        self.account = account
    }
}

