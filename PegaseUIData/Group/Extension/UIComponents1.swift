////
////  UIComponents.swift
////  DatabaseManager
////
////  Created by thierryH24 on 25/08/2025.
////
//
//import SwiftUI
//
//// A small wrapper enum to represent common SwiftUI button styles.
//enum UniformButtonVisualStyle {
//    case bordered
//    case borderedProminent
//    case plain
//}
//
//// Un bouton d'action uniformisé qui s'étire horizontalement, avec centrage et style cohérent.
////struct UniformActionButton<Content: View>: View {
////    let minWidth: CGFloat
////    let minHeight: CGFloat
////    let style: UniformButtonVisualStyle
////    let tint: Color?
////    let action: () -> Void
////    @ViewBuilder let content: () -> Content
////
////    init(
////        minWidth: CGFloat = 200,
////        minHeight: CGFloat = 100,
////        style: UniformButtonVisualStyle = .bordered,
////        tint: Color? = nil,
////        action: @escaping () -> Void,
////        @ViewBuilder content: @escaping () -> Content
////    ) {
////        self.minWidth = minWidth
////        self.minHeight = minHeight
////        self.style = style
////        self.tint = tint
////        self.action = action
////        self.content = content
////    }
////
////    var body: some View {
////        Button(action: action) {
////            HStack {
////                Spacer(minLength: 0)
////                content()
////                Spacer(minLength: 0)
////            }
////            .frame(minWidth: minWidth, minHeight: minHeight) // Assure largeur/hauteur minimales
////        }
////        .applyUniformStyle(style)
////        .frame(maxWidth: .infinity)
////        .applyTint(tint)
////    }
////}
////
////// Variante pratique: texte + icône SF Symbols optionnelle
////struct UniformLabeledButton: View {
////    let title: String
////    let systemImage: String?
////    let minWidth: CGFloat
////    let minHeight: CGFloat
////    let style: UniformButtonVisualStyle
////    let tint: Color?
////    let action: () -> Void
////
////    init(
////        _ title: String,
////        systemImage: String? = nil,
////        minWidth: CGFloat = 300,
////        minHeight: CGFloat = 44, // hauteur par défaut plus “bouton”
////        style: UniformButtonVisualStyle = .bordered,
////        tint: Color? = nil,
////        action: @escaping () -> Void
////    ) {
////        self.title = title
////        self.systemImage = systemImage
////        self.minWidth = minWidth
////        self.minHeight = minHeight
////        self.style = style
////        self.tint = tint
////        self.action = action
////    }
////
////    var body: some View {
////        UniformActionButton(minWidth: minWidth, minHeight: minHeight, style: style, tint: tint, action: action) {
////            HStack(spacing: 8) {
////                if let systemImage {
////                    Image(systemName: systemImage)
////                }
////                Text(title)
////            }
////        }
////    }
////}
////
////// Petit utilitaire pour appliquer une teinte optionnelle
////private extension View {
////    @ViewBuilder
////    func applyTint(_ tint: Color?) -> some View {
////        if let tint {
////            self.tint(tint)
////        } else {
////            self
////        }
////    }
////
////    @ViewBuilder
////    func applyUniformStyle(_ style: UniformButtonVisualStyle) -> some View {
////        switch style {
////        case .bordered:
////            self.buttonStyle(.bordered)
////        case .borderedProminent:
////            self.buttonStyle(.borderedProminent)
////        case .plain:
////            self.buttonStyle(.plain)
////        }
////    }
////}
