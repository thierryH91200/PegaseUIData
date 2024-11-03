//
//  EntityCarnetCheques.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityCarnetCheques {
    var name: String?
    var nbCheques: Int32? = 0
    var numPremier: Int32? = 0
    var numSuivant: Int32? = 0
    var prefix: String?
    var uuid: UUID?
    var account: EntityAccount?
    public init() {

    }
    
}
