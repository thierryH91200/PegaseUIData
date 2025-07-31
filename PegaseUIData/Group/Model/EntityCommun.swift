//
//  RntityCommun.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 14/03/2025.
//

import Foundation
import SwiftData
import SwiftUI

enum EnumError: Error {
    case contextNotConfigured
    case accountNotFound
    case invalidStatusType
    case saveFailed
    case fetchFailed
}

final class DataContext {
    static let shared = DataContext()
    var context: ModelContext?
    var undoManager: UndoManager?

    init() {}
}
