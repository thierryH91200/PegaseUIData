//
//  EntityBankStatement.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityBankStatement {
    var dateCB: Date?
    var dateDebut: Date?
    var dateFin: Date?
    var dateInter: Date?
    var number: Double? = 0.0
    @Attribute(.externalStorage) var pdfDoc: Data?
    var pdfName: String?
    var soldeCB: Double? = 0.0
    var soldeDebut: Double? = 0.0
    var soldeFin: Double? = 0.0
    var soldeInter: Double? = 0.0
    var uuid = UUID()
    var account: EntityAccount?

    public init() {

    }
    
}
