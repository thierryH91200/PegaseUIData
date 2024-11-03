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
    var adress: String?
    var bank: String?
    var complement: String?
    var country: String?
    var cp: Int32? = 0
    var email: String?
    var fonction: String?
    var mobile: String?
    var name: String?
    var phone: String?
    var town: String?
    var uuid: UUID?
    var account: EntityAccount?

    public init() {

    }
    
}
