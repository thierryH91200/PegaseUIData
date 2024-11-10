//
//  EntityPreference.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityPreference {
    var signe: Bool?
    var statut: Int16? = 0

    var category: EntityCategory?
    var paymentMode: EntityPaymentMode?
    
    var account: EntityAccount?

    public init() {

    }
    
}
