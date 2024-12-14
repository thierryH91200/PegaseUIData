//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI

struct ModePaymentView: View {
    @State private var items: [DialogItem] = [
        DialogItem(name: "Bank Card", color: .green, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Check", color: .yellow, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Discount", color: .gray, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Espèces", color: .blue, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Prelevement", color: .red, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Retrait espèces", color: .orange, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E"),
        DialogItem(name: "Virement", color: .brown, account: "Current account", surname: "Doe", firstName: "John", number: "00045700E")
    ]
    
    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: DialogItem.ID? = nil

    var body: some View {
        VStack(spacing: 10) {
            Table(items, selection: $selectedItem) {
                TableColumn("Name", value: \.name)
                TableColumn("Color") { item in
                    Rectangle()
                        .fill(item.color)
                        .frame(width: 40, height: 20)
                }
                TableColumn("Account", value: \.account)
                TableColumn("Surname", value: \.surname)
                TableColumn("First name", value: \.firstName)
                TableColumn("Number", value: \.number)
            }
            .frame(height: 300)
            
            HStack {
                Button(action: addItem) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)

                Button(action: removeSelectedItem) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedItem == nil) // Désactive si aucune ligne n'est sélectionnée
            }
            .padding()
        }
        .frame(width: 700, height: 400)
        .padding()
    }
    
    private func addItem() {
        let newItem = DialogItem(name: "New Item", color: .gray, account: "New account", surname: "Doe", firstName: "John", number: "00000000E")
        items.append(newItem)
    }
    
    private func removeSelectedItem() {
        if let selectedID = selectedItem, let index = items.firstIndex(where: { $0.id == selectedID }) {
            items.remove(at: index)
            selectedItem = nil // Réinitialise la sélection
        }
    }
}

struct DialogItem: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var account: String
    var surname: String
    var firstName: String
    var number: String
}

