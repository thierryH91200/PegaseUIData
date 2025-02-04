//
//  EntitySousOperations.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntitySousOperations {
    var amount: Double? = 0.0
    var libelle: String?
    var category: EntityCategory?
    var transaction: EntityTransactions?
   
    @Attribute(.unique) var uuid: UUID = UUID()
    public var id: UUID { uuid }

    public init() {

    }
}
