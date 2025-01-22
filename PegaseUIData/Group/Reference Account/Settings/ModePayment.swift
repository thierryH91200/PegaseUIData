//
//  ModePayment.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI

struct ModePaymentView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var accountManager = CurrrentAccountManager.shared

    var account = CurrrentAccountManager.shared.getAccount()!

    // Ajoutez un état pour suivre l'élément sélectionné
    @State private var selectedItem: EntityPaymentMode.ID? = nil
    
    @State private var modePayments: [EntityPaymentMode] = []

    var body: some View {
        VStack(spacing: 10) {
            Table(modePayments, selection: $selectedItem) {
                TableColumn("Name", value: \EntityPaymentMode.name)
                TableColumn("Color") { item in
                    Rectangle()
                        .fill(Color(item.color))
                        .frame(width: 40, height: 20)
                }
                TableColumn("Account", value: \EntityPaymentMode.account.name)
                TableColumn("Surname") { paymentMode in
                    Text(paymentMode.account.identity?.surName ?? "Unknown") }
                TableColumn("First name")  { paymentMode in
                    Text(paymentMode.account.identity?.name ?? "Unknown") }
                TableColumn("Number") { paymentMode in
                    Text(paymentMode.account.initAccount?.codeAccount ?? "Unknown") }
            }
            .frame(height: 300)
            
            Spacer()
            
            HStack {
                Button(action: {
                    addItem(name: "Default Name", color: .blue)
                }) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Utilise tout l'espace parent et aligne en haut
        .padding()
        .onChange(of: CurrrentAccountManager.shared.currentAccount!) { old, newAccount in
            print(newAccount.name)
            // Rafraîchir `modePayments` quand le compte change
            Task {
                await loadData(for: newAccount)
            }
        }
        .onAppear {
            // Charger les paiements lors du premier affichage
            
            Task {
                await loadData(for: account)
            }
        }
    }
    
    func loadData(for account: EntityAccount) async {
        
        PaymentModeManager.shared.configure(with: modelContext)

        // Chargement asynchrone des données
        modePayments = await PaymentModeManager.shared.getAllDatas(for: account)

        if let firstItem = modePayments.first {
            print("First item ID: \(firstItem.id)") // Vérifie que l'ID existe
        } else {
            print("No items in modePayments")
        }
    }

    private func addItem(name: String, color: Color) {
        print("account : ", account.name)
        PaymentModeManager.shared.configure(with: modelContext)
        let viewModel = PaymentModeViewModel(account: account)
        let account = viewModel.account
        
        do {
            // Essayez de créer l'entité
            if let entity = try PaymentModeManager.shared.create(account: account, name: name, color: NSColor.fromSwiftUIColor(color)){
                
                // Ajoutez l'entité au contexte
                modelContext.insert(entity)
            } else {
                print("Erreur : L'entité n'a pas pu être créée.")
            }

            // Sauvegardez le contexte pour persister les modifications
            try modelContext.save()
            print("Payment mode added successfully.")
        } catch {
            // Gérer l'erreur en cas d'échec
            print("Erreur lors de l'ajout de l'entité : \(error)")
        }
    }

    private func editItem(name: String, color: Color, paymentMode: EntityPaymentMode) {
        print("Editing item: \(paymentMode.name)")
        
        // Mettre à jour les propriétés de l'élément dans SwiftData
        PaymentModeManager.shared.configure(with: modelContext)
        PaymentModeManager.shared.update(entity: paymentMode, name: name, color: NSColor.fromSwiftUIColor(color))
        
        // Recharger la liste des éléments
        if let index = modePayments.firstIndex(where: { $0.id == paymentMode.id }) {
            modePayments[index].name = name
            modePayments[index].color = NSColor.fromSwiftUIColor(color) // Assumez que vous stockez une couleur NSColor
        }
    }
    
    private func removeSelectedItem() {
        if let selectedID = selectedItem, let mode = modePayments.first(where: { $0.id == selectedID }) {
            print("Removing item with ID \(selectedID)")

            // Supprimez l'entité du contexte de données
            modelContext.delete(mode)

            // Sauvegardez les changements dans le contexte
            do {
                try modelContext.save()
                selectedItem = nil // Réinitialise la sélection
            } catch {
                print("Erreur lors de la suppression de l'entité : \(error)")
            }
        }
    }
}


