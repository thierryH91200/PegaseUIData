//
//  Status.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 12/11/2024.
//

import SwiftUI

final class Status {
    
    static let shared = Status()
    
    init() {}

    enum TypeOfStatus: Int16, CaseIterable {
        case engaged = 0
        case pending = 1
        case completed = 2

        var label: String {
            switch self {
            case .engaged: return "Engaged"
            case .pending: return "Pending"
            case .completed: return "Completed"
            }
        }

        var color: Color {
            switch self {
            case .engaged: return .blue
            case .pending: return .black
            case .completed: return .green
            }
        }
    }

    // Méthode pour retrouver un status en fonction de son label
    func findStatus(status: String) -> Int16 {
        if let foundStatus = TypeOfStatus.allCases.first(where: { $0.label == status }) {
            return foundStatus.rawValue
        }
        return TypeOfStatus.engaged.rawValue // Valeur par défaut
    }
}

