//
//  EntityCommun.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 14/03/2025.
//

import Foundation
import SwiftData
import SwiftUI
import os

enum EnumError: Error {
    case contextNotConfigured
    case accountNotFound
    case invalidStatusType
    case saveFailed
    case fetchFailed
}

// Singleton global pour centraliser le ModelContext et l'UndoManager.
// ContainerManager et d'autres parties du code les injectent ici.
final class DataContext {
    static let shared = DataContext()
    var context: ModelContext?
    var undoManager: UndoManager?

    private init() {}
}

// Logging utilitaire
@inline(__always)
func printTag(_ message: @autoclosure () -> String,
              category: String = "App",
              file: StaticString = #fileID,
              function: StaticString = #function,
              line: UInt = #line) {
    let text = message()
    #if canImport(os)
    if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PegaseUIData",
                            category: category)
        logger.info("[\(file):\(line)] \(function, privacy: .public) — \(text, privacy: .public)")
        return
    }
    #endif
    // Fallback
    print("[\(category)] \(file):\(line) \(function) — \(text)")
}


