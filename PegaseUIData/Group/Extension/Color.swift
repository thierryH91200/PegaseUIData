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

func colorFromName(_ name: String) -> NSColor {
    switch name.lowercased() {
    case "green": return NSColor.green
    case "yellow": return NSColor.yellow
    case "blue": return NSColor.blue
    case "red": return NSColor.red
    case "gray": return NSColor.gray
    case "orange": return NSColor.orange
    case "brown": return NSColor.brown
    case "mint": return NSColor.systemMint
    default: return NSColor.black
    }
}

// Extension pour convertir SwiftUI Color en NSColor
extension NSColor {
    static func fromSwiftUIColor(_ color: Color) -> NSColor {
        if let cgColor = color.cgColor {
            return NSColor(cgColor: cgColor) ?? NSColor.black
        } else {
            return NSColor.black
        }
    }
}

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

extension NSColor {
    static func fromString(_ string: String) -> NSColor {
        switch string.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "brown": return .brown
        case "gray": return .gray
        case "orange": return .orange
        case "purple": return .purple
        default: return .clear
        }
    }
}


