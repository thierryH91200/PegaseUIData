//
//  EntityIdentity.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData

@Model
public class EntityIdentity {
    var adress: String = ""
    var complement: String = ""
    var country: String = ""
    var cp: Int32? = 0
    var email: String = ""
    var mobile: String = ""
    var name: String = ""
    var nameImage: String = ""
    var phone: String = ""
    var surName: String = ""
    var town: String = ""
    
    var account: EntityAccount?
    
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
    
    public init() {
    }
}


