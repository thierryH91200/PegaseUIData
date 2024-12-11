//
//  Color.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 13/11/2024.
//

import SwiftUI
import Foundation
import SwiftData

class ColorTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? NSColor else { return nil }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
            return color
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSColor.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(ColorTransformer(), forName: .init("ColorTransformer"))
    }
}

//enum Color: String {
//    case black
//    case blue
//    case brown
//    case gray
//    case green
//    case orange
//    case darkGray
//    case purple
//    case red
//    case yellow
//    
//    var color: Color {
//        switch self {
//        case .red:
//            return .red
//        case .blue:
//            return .blue
//        case .green:
//            return .green
//        case .black:
//            return .black
//        case .purple:
//            return .purple
//        case .orange:
//            return .orange
//        case .brown:
//            return .brown
//        case .darkGray:
//            return .darkGray
//        case .yellow:
//            return .yellow
//        case .gray:
//            return .gray
//        }
//    }
//}




extension Color {
    init?(colorName: String) {
        let color = colorName.lowercased()
        
        switch color {
        case "red":
            self = .red
        case "orange":
            self = .orange
        case "yellow":
            self = .yellow
        case "green":
            self = .green
        case "indigo":
            self = .indigo
        case "purple":
            self = .purple
        case "cyan":
            self = .cyan
        case "mint":
            self = .mint
        case "teal":
            self = .teal
        case "brown":
            self = .brown
        case "gray":
            self = .gray
        default:
            self = .blue
        }
    }
}

enum EntityColor: String, Codable {
    case black, blue, brown, gray, green, orange, darkGray, purple, red, yellow
    
    var nsColor: Color {
        switch self {
        case .black: return .black
        case .blue: return .blue
        case .brown: return .brown
        case .gray: return .gray
        case .green: return .green
        case .orange: return .orange
        case .darkGray: return .gray
        case .purple: return .purple
        case .red: return .red
        case .yellow: return .yellow
        }
    }
}


