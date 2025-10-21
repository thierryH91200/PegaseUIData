//
//  TreasuryCurve.swift
//  PegaseUIData
//
//  Created by thierryH24 on 11/10/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine



struct TransactionLocal: View {
    
    @EnvironmentObject private var listManager: ListTransactionsManager
    @EnvironmentObject private var transactionManager: TransactionSelectionManager

    @State private var filteredTransactions: [EntityTransaction] = []
    @State private var selectedTransactionID: EntityTransaction.ID? = nil

    private let formatterPrice: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .currency
        return f
    }()

    var body: some View {
        List {
            Section(header: headerList) {
                ForEach(filteredTransactions.sorted { $0.dateOperation > $1.dateOperation }, id: \.id) { tx in
                    TransactionRow(
                        tx: tx,
                        isSelected: tx.id == selectedTransactionID,
                        formatterPrice: formatterPrice)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleTap(on: tx)
                    }
                    .background {
                        if tx.id == selectedTransactionID {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.18),
                                    Color.accentColor.opacity(0.10)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Rectangle().fill(Color.white)
                        }
                    }
                }
            }
            .onAppear {
                filteredTransactions = []
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsSelectionChanged)) { _ in
            filteredTransactions = listManager.listTransactions
        }
    }
    private func handleTap(on tx: EntityTransaction) {
        // Toggle local selection highlight
        if selectedTransactionID == tx.id {
            selectedTransactionID = nil
            // Clear selection in the shared manager for a clean state
            transactionManager.selectedTransaction = nil
            transactionManager.selectedTransactions = []
        } else {
            selectedTransactionID = tx.id
            // Propagate simple selection (required by OperationDialogView.loadTransactionData)
            transactionManager.selectedTransaction = tx
            transactionManager.selectedTransactions = [tx]
            // Also notify listeners that rely on NotificationCenter
            NotificationCenter.default.post(name: .transactionSelectionChanged, object: tx)
        }
        // Ensure we're not in creation mode so OperationDialogView reacts
        transactionManager.isCreationMode = false
    }

    
    private var headerList: some View {
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 4) {
                    Text("Date of pointing :")
                        .frame(minWidth: 200, alignment: .leading)
                    Text("Date operation")
                        .frame(minWidth: 200, alignment: .leading)
                    Text("Status")
                        .frame(minWidth: 120, alignment: .leading)
                    Text("Mode")
                        .frame(minWidth: 140, alignment: .leading)
                    Text("Statement")
                        .frame(minWidth: 160, alignment: .leading)
                }
                HStack(alignment: .top, spacing: 4) {
                    Text("Comment")
                        .frame(minWidth: 400, alignment: .leading)
                    Text("Rubric")
                        .frame(minWidth: 120, alignment: .leading)
                    Text("Category")
                        .frame(minWidth: 140, alignment: .leading)
                    Text("Amount")
                        .frame(minWidth: 160, alignment: .leading)
                }
            }
            .foregroundColor(.black)
        }
    }
}
    
struct TransactionRow: View {
    @EnvironmentObject private var colorManager: ColorManager

    let tx: EntityTransaction
    let isSelected: Bool
    let formatterPrice: NumberFormatter

    var body: some View {
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(tx)
        
        VStack(alignment: .leading, spacing: 6) {
            topRow
            bottomRow
        }
        .foregroundColor(textColor)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.18),
                        Color.accentColor.opacity(0.10)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Rectangle().fill(Color.white)
            }
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: isSelected ? 2 : 0)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.2) : .clear, radius: isSelected ? 4 : 0, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(tx.datePointage, style: .date)
                .frame(minWidth: 200, alignment: .leading)
            Text(tx.dateOperation, style: .date)
                .frame(minWidth: 200, alignment: .leading)
            Text(tx.statusString)
                .frame(minWidth: 120, alignment: .leading)
            Text(tx.paymentModeString)
                .frame(minWidth: 140, alignment: .leading)
            Text(tx.bankStatementString)
                .frame(minWidth: 160, alignment: .leading)
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(tx.sousOperations.first?.libelle ?? "—")
                .frame(minWidth: 400, alignment: .leading)
            Text(tx.sousOperations.first?.category?.rubric?.name ?? "—")
                .frame(minWidth: 120, alignment: .leading)
            Text(tx.sousOperations.first?.category?.name ?? "—")
                .frame(minWidth: 140, alignment: .leading)
            let amountString = formatterPrice.string(from: NSNumber(value: tx.amount)) ?? "—"
            Text(amountString)
                .bold()
                .frame(minWidth: 160, alignment: .leading)
        }
    }
}


