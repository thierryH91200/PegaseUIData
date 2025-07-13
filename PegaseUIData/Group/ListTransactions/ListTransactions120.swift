//
//  ListTransactions120.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 25/03/2025.
//

import SwiftUI
import SwiftData


struct TransactionLigne: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var transactionManager   : TransactionSelectionManager
    @EnvironmentObject private var colorManager : ColorManager
    
    let transaction: EntityTransaction
    @Binding var selectedTransactions: Set<UUID>
    let visibleTransactions: [EntityTransaction]
    
    @State var showTransactionInfo: Bool = false
    @GestureState private var isShiftPressed = false
    @GestureState private var isCmdPressed = false
    
    @State private var backgroundColor = Color.clear
    
    var isSelected: Bool {
        selectedTransactions.contains(transaction.id)
    }
    
    var body: some View {
        let isSelected = selectedTransactions.contains(transaction.id)
        var backgroundColor = isSelected ? Color.blue.opacity(0.5) : Color.clear
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(transaction)
        
        HStack(spacing: 0) {
            Group {
                Text(transaction.datePointageString)
                    .frame(width: ColumnWidths.datePointage, alignment: .leading)
                verticalDivider()
                Text(transaction.dateOperationString)
                    .frame(width: ColumnWidths.dateOperation, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.libelle ?? "—")
                    .frame(width: ColumnWidths.libelle, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.category?.rubric?.name ?? "—")
                    .frame(width: ColumnWidths.rubrique, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.category?.name ?? "—")
                    .frame(width: ColumnWidths.categorie, alignment: .leading)
                verticalDivider()
                Text(transaction.sousOperations.first?.amountString ?? "—")
                    .frame(width: ColumnWidths.sousMontant, alignment: .leading)
                verticalDivider()
                Text(transaction.bankStatementString)
                    .frame(width: ColumnWidths.releve, alignment: .leading)
                verticalDivider()
                Text(transaction.checkNumber != "0" ? transaction.checkNumber : "—").frame(width: ColumnWidths.cheque, alignment: .leading)
                verticalDivider()
            }
            Group {
                Text(transaction.statusString)
                    .frame(width: ColumnWidths.statut, alignment: .leading)
                verticalDivider()
                Text(transaction.paymentModeString)
                    .frame(width: ColumnWidths.modePaiement, alignment: .leading)
                verticalDivider()
                Text(transaction.amountString)
                    .frame(width: ColumnWidths.montant, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(EdgeInsets()) // ⬅️ Supprime la marge à gauche des lignes
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .foregroundColor(textColor)
        .cornerRadius(8) // Arrondi les coins du fond sélectionné
        .contentShape(Rectangle()) // Permet de cliquer sur toute la ligne
        .onTapGesture {
            toggleSelection()
        }
        .onHover { hovering in
            if !isSelected {
                withAnimation {
                    backgroundColor = hovering ? Color.gray.opacity(0.1) : Color.clear
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isCmdPressed)   { _, state, _ in state = NSEvent.modifierFlags.contains(.command) }
                .updating($isShiftPressed) { _, state, _ in state = NSEvent.modifierFlags.contains(.shift) }
        )
        .contextMenu {
            // Afficher les détails
            Button(action: {
                transactionManager.selectedTransaction = transaction
                transactionManager.isCreationMode = false
                showTransactionInfo = true
            }) {
                Label("Show details", systemImage: "info.circle")
            }
            // Liste des noms et couleurs des status
            let names = [ String(localized :"Planned"),
                          String(localized :"In progress"),
                          String(localized :"Executed") ]
            Menu {
                Button(names[0]) { mettreAJourStatusPourSelection(nouveauStatus: names[0]) }
                Button(names[1]) { mettreAJourStatusPourSelection(nouveauStatus: names[1]) }
                Button(names[2]) { mettreAJourStatusPourSelection(nouveauStatus: names[2]) }
            } label: {
                Label("Change status", systemImage: "square.and.pencil")
            }
            .disabled(selectedTransactions.isEmpty)
            
            Button(role: .destructive, action: {
                supprimerTransactionsSelectionnees()
            }) {
                Label("Remove", systemImage: "trash")
            }
            .disabled(selectedTransactions.isEmpty)
            .padding()
        }
        .popover(isPresented: $showTransactionInfo, arrowEdge: .top) {
            if let index = ListTransactionsManager.shared.listTransactions.firstIndex(where: { $0.id == transaction.id }) {
                TransactionDetailView(currentSectionIndex: index, selectedTransaction: $selectedTransactions)
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                Text("Error: Transaction not found in the list.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        // Keyboard shortcut: Cmd+A to select all transactions, Escape to deselect all
        .onAppear {
            backgroundColor = isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor)
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "a" {
                    // Tout sélectionner
                    for transaction in ListTransactionsManager.shared.listTransactions {
                        selectedTransactions.insert(transaction.id)
                    }
                    transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions
                    return nil
                }
                
                if event.keyCode == 53 { // Escape key
                    // Tout désélectionner
                    selectedTransactions.removeAll()
                    transactionManager.selectedTransaction = nil
                    transactionManager.selectedTransactions = []
                    return nil
                }
                return event
            }
        }
    }
    
    @ViewBuilder
    func verticalDivider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 2, height: 20)
            .padding(.horizontal, 2)
    }
    
    private func transaction(for id: UUID) -> EntityTransaction? {
        _ = selectedTransactions.compactMap { id in
            transaction(for: id)
        }
        return ListTransactionsManager.shared.listTransactions.first { $0.id == id }
    }
    
    private func toggleSelection() {
        let isCommand = NSEvent.modifierFlags.contains(.command)
        let isShift = NSEvent.modifierFlags.contains(.shift)
        
        if isShift, let lastID = transactionManager.lastSelectedTransactionID,
           let lastIndex = visibleTransactions.firstIndex(where: { $0.id == lastID }),
           let currentIndex = visibleTransactions.firstIndex(where: { $0.id == transaction.id }) {

            let range = lastIndex <= currentIndex
                ? lastIndex...currentIndex
                : currentIndex...lastIndex

            // Sélectionne tous les IDs dans la plage visible
            let idsInRange = visibleTransactions[range].map { $0.id }

            // Nettoie l’ancienne sélection et ajoute la nouvelle
            selectedTransactions.removeAll()
            selectedTransactions.formUnion(idsInRange)
            
        } else if isCommand {
            if selectedTransactions.contains(transaction.id) {
                selectedTransactions.remove(transaction.id)
            } else {
                selectedTransactions.insert(transaction.id)
            }
            // MAJ du dernier élément sélectionné, très important pour la sélection shift !
            transactionManager.lastSelectedTransactionID = transaction.id
        } else {
            selectedTransactions.removeAll()
            selectedTransactions.insert(transaction.id)
            // MAJ du dernier élément sélectionné, très important pour la sélection shift !
            transactionManager.lastSelectedTransactionID = transaction.id
        }

        if let firstSelectedId = selectedTransactions.first {
            transactionManager.selectedTransaction = ListTransactionsManager.shared.listTransactions.first { $0.id == firstSelectedId }
        }
        transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
        transactionManager.isCreationMode = false
    }
    
    private func supprimerTransactionsSelectionnees() {
        withAnimation {
            // Copie locale des éléments à supprimer
            let transactionsToDelete = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            
            // Supprime du contexte si non déjà supprimé
            for transaction in transactionsToDelete {
                if !transaction.isDeleted {
                    ListTransactionsManager.shared.delete(entity: transaction)
                }
            }
            
            // Vide la sélection
            selectedTransactions.removeAll()
            _ = ListTransactionsManager.shared.getAllData(ascending: false)
        }
    }
    private func mettreAJourStatusPourSelection(nouveauStatus: String) {
        withAnimation {
            let selected = ListTransactionsManager.shared.listTransactions.filter { selectedTransactions.contains($0.id) }
            let status = StatusManager.shared.find(name: nouveauStatus)!
            for transaction in selected {
                transaction.status = status
            }
        }
    }
}
