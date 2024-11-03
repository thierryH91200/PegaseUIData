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
    var account: EntityAccount?
    var category: EntityCategory?
    var paymentMode: EntityPaymentMode?
    public init() {

    }
    
}
