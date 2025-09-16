//
//  UTType+CustomTypes.swift
//  WelcomeTo
//
//  Created by thierryH24 on 05/08/2025.
//

import UniformTypeIdentifiers

extension UTType {
    static var sqlite: UTType {
        UTType(filenameExtension: "sqlite") ?? .data
    }
    static var store: UTType {
        UTType(filenameExtension: "store") ?? .data
    }
    static var database: UTType {
        UTType(filenameExtension: "sqlite") ?? .data
    }
}

extension UTType {
    static var swiftDataStore: UTType {
//        UTType(importedAs: "com.yourcompany.database-manager.store")
        // Or:
         UTType(filenameExtension: "store", conformingTo: .data) ?? .data
    }
}

