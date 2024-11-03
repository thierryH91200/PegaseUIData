//
//  EntityIdentity.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
//
//

import Foundation
import SwiftData


@Model public class EntityIdentity {
    var adress: String?
    var complement: String?
    var country: String?
    var cp: Int32? = 0
    var email: String?
    var mobile: String?
    var name: String? = "\"\""
    var nameImage: String?
    var phone: String?
    var surName: String?
    var town: String?
    var account: EntityAccount?
    public init() {

    }
    
}
