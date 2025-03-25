//
//  ListTransactions2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 23/03/2025.
//

import SwiftUI
import SwiftData


struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var transactionManager: TransactionSelectionManager
    
    let transaction: EntityTransactions
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transaction Details")
                .font(.title)
                .bold()
                .padding(.bottom, 10)
            
            HStack {
                Text("Create at :")
                    .bold()
                Spacer()
                Text(transaction.createAt != nil ? Self.dateFormatter.string(from: transaction.createAt!) : "—")
            }
            HStack {
                Text("Update at :")
                    .bold()
                Spacer()
                Text(transaction.updatedAt != nil ? Self.dateFormatter.string(from: transaction.updatedAt!) : "—")
            }

            Divider()

            HStack {
                Text("Amount :")
                    .bold()
                Spacer()
                Text("\(String(format: "%.2f", transaction.amount)) €")
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
            }
            Divider()
            
            HStack {
                Text("Date of pointing :")
                    .bold()
                Spacer()
                Text(transaction.datePointage != nil ? Self.dateFormatter.string(from: transaction.datePointage!) : "—")
            }
            HStack {
                Text("Date operation :")
                    .bold()
                Spacer()
                Text(transaction.dateOperation != nil ? Self.dateFormatter.string(from: transaction.dateOperation!) : "—")
            }
            HStack {
                Text("Payment method :")
                    .bold()
                Spacer()
                Text(transaction.paymentMode?.name ?? "—")
            }
            HStack {
                Text("Bank statement :")
                    .bold()
                Spacer()
                Text(String(transaction.bankStatement))
            }
            
            HStack {
                Text("Statut :")
                    .bold()
                Spacer()
                Text(transaction.status?.name ?? "N/A")
            }
            
            Divider()
            
            // Section pour les sous-opérations
            if let premiereSousOp = transaction.sousOperations.first {
                HStack {
                    Text("Comment :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.libelle ?? "Sans libellé")
                }
                HStack {
                    Text("Rubric :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.category?.rubric?.name ?? "N/A")
                }
                HStack {
                    Text("Category :")
                        .bold()
                    Spacer()
                    Text(premiereSousOp.category?.name ?? "N/A")
                }
                HStack {
                    Text("Amount :")
                        .bold()
                    Spacer()
                    Text("\(String(format: "%.2f", premiereSousOp.amount)) €")
                        .foregroundColor(premiereSousOp.amount >= 0 ? .green : .red)
                }
            } else {
                Text("No sub-operations available")
                    .italic()
                    .foregroundColor(.gray)
            }
            
            // Si vous avez plusieurs sous-opérations, vous pourriez ajouter une liste ici
            
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    transactionManager.selectedTransaction = nil
                    dismiss()
                }) {
                    Text("Close")
                        .frame(width: 100)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

