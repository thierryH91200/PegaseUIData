//
//  EntityDummy.swift
//  PegaseUIData
//
//  Created by thierryH24 on 19/10/2025.
//


import Foundation
import SwiftData

@Model
final class DummyModel {
    @Attribute(.unique) var id: UUID

    init() {
        self.id = UUID()
    }
}
