//
//  EntityRubric.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
////

import AppKit
import SwiftData
import SwiftUI



@Model
public class EntityRubric {

    var name: String
    
//    @Attribute(.transformable(by: "NSColorValueTransformer")) var color: NSObject?
    @Attribute(.ephemeral) var total: Double = 0.0

    var uuid: UUID
    
    var account: EntityAccount?
    
    @Relationship(deleteRule: .cascade) var category: [EntityCategory]?
    
    public init( name: String, uuid: UUID) {
//        public init( name: String, color: Color, uuid: UUID) {
        self.name = name
//        self.color = NSColor(color)
        self.uuid = uuid

    }
    
}


//@Model
//class ColorModel {
//    var name: String
//    @Attribute(.transformable(by: ColorTransformer.self)) var color: UIColor
//    
//    init(name: String, color: Color) {
//        self.name = name
//        self.color = UIColor(color)
//    }
//}
