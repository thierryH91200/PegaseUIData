//
//  Extensions.swift
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
}
