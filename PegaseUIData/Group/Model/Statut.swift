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
        case planifie = 0
        case engage = 1
        case realise = 2

        var label: String {
            switch self {
            case .planifie: return "Planifie"
            case .engage: return "Statut.Engaged"
            case .realise: return "Statut.Realise"
            }
        }

        var color: Color {
            switch self {
            case .planifie: return .black
            case .engage: return .blue
            case .realise: return .green
            }
        }
    }

    // Méthode pour retrouver un statut en fonction de son label
    func findStatut(statut: String) -> Int16 {
        if let foundStatut = TypeOfStatut.allCases.first(where: { $0.label == statut }) {
            return foundStatut.rawValue
        }
        return TypeOfStatut.engage.rawValue // Valeur par défaut
    }
}

