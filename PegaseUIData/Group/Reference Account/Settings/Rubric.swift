//
//  Rubric.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//


import SwiftUI
import SwiftData



struct RubricView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \EntityRubric.name) private var rubriques: [EntityRubric]
    @State private var expandedRubriques: [String: Bool] = [:]
    @State private var selectedCategory: EntityCategory?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        rubricList()
                            .padding(.vertical, 0)
                    }
                    .padding(10)
                }
                .onAppear {
                    RubricManager.shared.configure(with: modelContext)
                    
                    if let url = Bundle.main.url(forResource: "rubrique", withExtension: "csv") {
                        RubricManager.shared.importCSV(from: url)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 3)

                Spacer(minLength: 0)
            }
            .frame(width: 400, height: 500)
            .padding()
            .background(Color.gray.opacity(0.2))
            .position(x: geometry.size.width / 2, y: 0)
            .offset(y: 350) // Ajustez cette valeur selon vos besoins
        }
    }

    // Fonction séparée pour générer la liste des rubriques
    @ViewBuilder
    private func rubricList() -> some View {
        ForEach(rubriques, id: \.name) { rubrique in
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedRubriques[rubrique.name] ?? true },
                    set: { expandedRubriques[rubrique.name] = $0 }
                ),
                content: {
                    ForEach(rubrique.categorie, id: \.name) { category in
                        categoryRow(category)
                            .padding(.vertical, 0) // Supprimer l'espace inutile
                    }
                },
                label: {
                    HStack {
                        Text(rubrique.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(rubrique.color))
                            .frame(height: 20)
                        Spacer()
                        Rectangle()
                            .fill(Color(rubrique.color))
                            .frame(width: 40, height: 10)
                    }
                    .padding(.vertical, 2) // Réduire l'espace au-dessus et en dessous
                }
            )
            .padding(.vertical, 0)
        }
    }

    // Fonction pour afficher chaque catégorie avec une ligne HStack
    @ViewBuilder
    private func categoryRow(_ category: EntityCategory) -> some View {
        HStack {
            Text(category.name)
                .font(.system(size: 12))
                .frame(minWidth: 150, alignment: .leading)
            Text("🎯 \(category.objectif.description)")
                .font(.system(size: 12))
        }
        .padding(.leading, 5)
        .frame(height: 18)
        .background(selectedCategory?.name == category.name ? Color.blue.opacity(0.3) : Color.clear)
        .onTapGesture {
            selectedCategory = category
        }
    }
}

