//
//  Statut.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 12/11/2024.
//

import SwiftUI
import SwiftData

@Model final class Statut {
    
    static let shared = Statut()
    
    init() {}

    enum TypeOfStatut: Int16, CaseIterable {
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
            case .engaged: return .black
            case .pending: return .blue
            case .completed: return .green
            }
        }
    }

    // Méthode pour retrouver un statut en fonction de son label
    func findStatut(statut: String) -> Int16 {
        if let foundStatut = TypeOfStatut.allCases.first(where: { $0.label == statut }) {
            return foundStatut.rawValue
        }
        return TypeOfStatut.engaged.rawValue // Valeur par défaut
    }
}

