//
//  EntityRubric.swift
//  Pegase
//
//  Created by Thierry hentic on 03/11/2024.
////

import AppKit
import SwiftData
import SwiftUI



@Model
public class EntityRubric {
    
    var name: String = ""
    
    //    @Attribute(.transformable(by: "NSColorValueTransformer")) var color: NSObject?
    @Attribute(.ephemeral) var total: Double = 0.0
    var uuid: UUID = UUID()
    var account: EntityAccount?
    
    @Relationship(deleteRule: .cascade) var category: [EntityCategory]?
//    
//    public init( name: String, /*color: Color,*/ uuid: UUID) {
    public init( name: String, account: EntityAccount) {
        self.name = name
        //        self.color = NSColor(color)
        self.uuid = UUID()
        self.account = account
    }
}

//@Model
//class ColorModel {
//    var name: String
//    @Attribute(.transformable(by: ColorTransformer.self)) var color: UIColor
//
//    init(name: String, color: Color) {
//        self.name = name
//        self.color = UIColor(color)
//    }
//}





final class RubricManager: ObservableObject {
    
    var currentAccount: EntityAccount?

    static let shared = RubricManager()
    
    @Query private var entitiesRubric: [EntityRubric]
    @Environment(\.modelContext) private var modelContext: ModelContext

    
    init() {}

    func findOrCreate(account: EntityAccount, name: String, color: Color) -> EntityRubric {
        if let entityRubric = find(account: account, name: name) {
            return entityRubric
        } else {
//            let newEntity = EntityRubric(name: name, color: color, uuid: UUID(), account: account)
            let newEntity = EntityRubric(name: name, account: account)
            modelContext.insert(newEntity)
            return newEntity
        }
    }

    func find(account: EntityAccount, name: String) -> EntityRubric? {
        entitiesRubric.first { $0.account == account && $0.name == name }
    }
    
    func remove(entity: EntityRubric) {
        modelContext.delete(entity)  // Utilisez modelContext pour supprimer l'entité
    }

    func getAllDatas(for account: EntityAccount) -> [EntityRubric] {
        entitiesRubric.filter { $0.account == account }
    }
    
    fileprivate func addRubric(_ key: [String: String]) {
        guard entitiesRubric.isEmpty else {
            // Ajout à la première rubrique existante
            if let rubric = entitiesRubric.first {
                let newCategory = EntityCategory(name: key["categorie"] ?? "", objectif: Double(key["objectif"] ?? "0.0")!, rubric: rubric)
                rubric.category?.insert(newCategory, at: 0)
            }
            return
        }
        
        // Ajout d'une nouvelle rubrique si aucune n'existe
        let newRubric = EntityRubric(name: key["rubrique"] ?? "", color: Color(rawValue: key["color"]!) ?? .gray, account: currentAccount)
        let newCategory = EntityCategory(name: key["categorie"] ?? "", objectif: Double(key["objectif"] ?? "0.0")!, uuid: UUID(), rubric: newRubric)
        newRubric.category = [newCategory]
//        entitiesRubric.append(newRubric)
        modelContext.insert(newRubric)

    }

    func defaultEntity() {
        if entitiesRubric.isEmpty {
            if let content = loadCSV("rubrique") {
                let csv = CSwiftV(with: content, separator: ";", replace: "\r")
                csv.keyedRows?.forEach { addRubric($0) }
            }
        }
    }
    
    private func loadCSV(_ filename: String) -> String? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "csv") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

extension Color {
    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .black: return .black
        case .purple: return .purple
        case .orange: return .orange
        case .brown: return .brown
        case .gray: return .gray.opacity(0.7)
        case .yellow: return .yellow
        case .gray: return .gray
        default:
            return .black
        }
    }
}
