//
//  Outline Col.swift
//  HelloSwiftUI
//
//  Created by Thierry hentic on 06/01/2025.
//
import SwiftUI

let sampleData1 = [
    OutlineItemCol(name: "Parent 1", dateOperation: "Details P1", datePointage: "", bankStatement: "", children: [
        OutlineItemCol(name: "Child 1.1", dateOperation: "Details R1C1", datePointage: "Details R1C2", bankStatement: "Details R1C3"),
        OutlineItemCol(name: "Child 1.2", dateOperation: "Details R2C3", datePointage: "Details R2C3", bankStatement: "Details R2C3")
    ]),
    OutlineItemCol(name: "Parent 2", dateOperation: "Details P2", datePointage: "", bankStatement: "", children: [
        OutlineItemCol(name: "Child 2.1",dateOperation: "Details R1C1", datePointage: "Details R1C1", bankStatement: "Details R1C3"),
    ])
]

struct OutlineItemCol: Identifiable {
    let id = UUID()
    var name: String
    var dateOperation : String
    var datePointage: String
    var bankStatement: String
    var children: [OutlineItemCol]? = nil
    
    // Vérifie si l'item a des enfants
    var hasChildren: Bool {
        return children != nil && !children!.isEmpty
    }
}

struct OutlineViewWithColumnsDemo: View {
    
    @Environment(\.modelContext) var modelContext


    // État de sélection au niveau parent
    @State private var selectedId: UUID?

    var body: some View {
        CustomOutlineView(items: sampleData1, selection: $selectedId)
            .onAppear {
                ListTransactionsManager.shared.configure(with: modelContext)
                let transactions = ListTransactionsManager.shared.getAllDatas()
            }
    }
        
}

class ColumnWidth: ObservableObject {
    @Published var name:     CGFloat = 200
    @Published var details1:  CGFloat = 150
    @Published var details2: CGFloat = 150
    @Published var details3: CGFloat = 150  // Nouvelle colonne

    var total: CGFloat { name + details1 + details2 + details3 + 50 } // +50 pour le padding
    let minWidth: CGFloat = 50
    
    func resizeColumn(_ columnKeyPath: ReferenceWritableKeyPath<ColumnWidth, CGFloat>, by dragWidth: CGFloat) {
        let currentWidth = self[keyPath: columnKeyPath]
        let newWidth = currentWidth + dragWidth
        if newWidth >= minWidth {
            self[keyPath: columnKeyPath] = newWidth
        }
    }
}

struct ColumnDivider: View {
    let width: CGFloat = 4
    @Binding var isResizing: Bool
    var onDrag: (CGFloat) -> Void
    
    var body: some View {
        Rectangle()
            .fill(isResizing ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3))
            .frame(width: width)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        isResizing = true
                        onDrag(value.translation.width)
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
    }
}

struct ColumnHeaderView: View {
    @ObservedObject var widths: ColumnWidth
    @State private var isResizing: Bool = false

    var body: some View {
        HStack(spacing: 0) {  // Ajouter spacing: 0
            Text("Name")
                .font(.headline)
                .frame(width: widths.name, height: 25, alignment: .center)
            
            ColumnDivider(isResizing: $isResizing) { dragWidth in
                widths.resizeColumn(\.name, by: dragWidth)
            }

            Text("Date Transaction")
                .font(.headline)
                .frame(width: widths.details1, height: 25, alignment: .center)
            
            ColumnDivider(isResizing: $isResizing) { dragWidth in
                widths.resizeColumn(\.details1, by: dragWidth)
            }

            Text("Date of pointing")
                .font(.headline)
                .frame(width: widths.details2, height: 25, alignment: .center)
            
            ColumnDivider(isResizing: $isResizing) { dragWidth in
                widths.resizeColumn(\.details2, by: dragWidth)
            }
            
            Text("bankStatement")  // Nouvelle colonne
                .font(.headline)
                .frame(width: widths.details3, height: 25, alignment: .center)

        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .frame( height: 25 )
    }
}

// Vue pour un élément enfant
struct ChildRowView: View {
    let child: OutlineItemCol
    let isSelected: Bool
    @ObservedObject var widths: ColumnWidth

    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            Text("")
                .frame(width: 20)
            Text(child.name)
                .frame(width: widths.name - 20, alignment: .leading)
            Text(child.dateOperation)
                .frame(width: widths.details1, alignment: .leading)
                .foregroundColor(.gray)
            Text(child.datePointage)
                .frame(width: widths.details2, alignment: .leading)
                .foregroundColor(.gray)
            Text(child.bankStatement)  // Nouvelle colonne
                .frame(width: widths.details3, alignment: .leading)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 2)
        .padding(.horizontal)
        .background(isSelected ? Color.blue.opacity(0.5) : Color.clear)
        .frame(height: 25) // Ajouter une hauteur fixe
        .onTapGesture(perform: onSelect)
    }
}

// Vue pour un élément parent
struct ParentRowView: View {
    let item: OutlineItemCol
    let isExpanded: Bool
    let selectedId: UUID?
    @ObservedObject var widths: ColumnWidth

    let onToggle: () -> Void
    let onSelectChild: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Ajouter spacing: 0
            // Header
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .onTapGesture(perform: onToggle)
                    .frame(width: 20)
                Text(item.name)
                    .frame(width: widths.name - 20, alignment: .leading)
                    .fontWeight(.medium)
                    .lineLimit(1)  // Empêche le texte de déborder sur plusieurs lignes
                Text(item.datePointage)
                    .frame(width: widths.details1, alignment: .leading)
                    .foregroundColor(.gray)
                Text(item.dateOperation)
                    .frame(width: widths.details2, alignment: .leading)
                    .foregroundColor(.gray)
                Text(item.bankStatement)
                    .frame(width: widths.details3, alignment: .leading)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 2)
            .padding(.horizontal)
            .frame(height: 25) // Ajouter une hauteur fixe

            // Children
            if isExpanded, let children = item.children {
                ForEach(children) { child in
                    ChildRowView(
                        child: child,
                        isSelected: selectedId == child.id,
                        widths: widths,
                        onSelect: { onSelectChild(child.id) }
                    )
                }
            }
        }
    }
}

// Vue principale
struct CustomOutlineView: View {
    let items: [OutlineItemCol]
    @Binding var selection: UUID?
    @StateObject private var columnWidths = ColumnWidth()
    @State private var expandedItems: Set<UUID> = Set()
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                ColumnHeaderView(widths: columnWidths)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            ParentRowView(
                                item: item,
                                isExpanded: expandedItems.contains(item.id),
                                selectedId: selection,
                                widths: columnWidths,
                                onToggle: { toggleExpanded(item.id) },
                                onSelectChild: { selection = $0 }
                            )
                        }
                    }
                    .padding(.top, 1)  // Petit espace après le header
                }
            }
            .frame(width: columnWidths.total)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
            
            Spacer() // Force l'OutlineView vers la gauche
        }
        .padding()
    }
    
    private func toggleExpanded(_ id: UUID) {
        if expandedItems.contains(id) {
            expandedItems.remove(id)
        } else {
            expandedItems.insert(id)
        }
    }
}
