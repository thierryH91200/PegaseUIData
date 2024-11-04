//
//  EntityInitAccount.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityInitAccount {
    var bic: String?
    var cleRib: String?
    var codeAccount: String?
    var codeBank: String?
    var codeGuichet: String?
    var iban1: String?
    var iban2: String?
    var iban3: String?
    var iban4: String?
    var iban5: String?
    var iban6: String?
    var iban7: String?
    var iban8: String?
    var iban9: String?

    var engage: Double? = 0.0
    var prevu: Double? = 0.0
    var realise: Double? = 0.0
    
    var account: EntityAccount?
 
    public init() {

    }
    
}
