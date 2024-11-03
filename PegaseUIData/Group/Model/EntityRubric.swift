//
//  EntityRubric.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
////

import AppKit
import SwiftData



@Model
public class EntityRubric {

    var name: String
    var uuid: UUID
    var account: EntityAccount?
    
    @Attribute(.ephemeral) var total: Double? = 0.0
    @Relationship(deleteRule: .cascade) var category: [EntityCategory]?
    
    public init( name: String, uuid: UUID) {
//        self.color = color
        self.name = name
        self.uuid = uuid

    }
    
}
