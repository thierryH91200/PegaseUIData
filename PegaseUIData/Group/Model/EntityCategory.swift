//
//  EntityCategory.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityCategory {

    var name: String
    var objectif: Double? = 0.0
    var uuid: UUID?
    @Relationship(inverse: \EntitySchedule.category) var echeancier: [EntitySchedule]?
    @Relationship(inverse: \EntityPreference.category) var preference: EntityPreference?
    var rubric: EntityRubric?
    @Relationship(inverse: \EntitySousOperations.category) var sousOperations: [EntitySousOperations]?

    public init(name: String) {
        self.name = name

    }
    
}
