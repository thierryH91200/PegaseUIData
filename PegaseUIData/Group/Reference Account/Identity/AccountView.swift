//
//  AccountView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI

struct AccountView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Logo et Rapport Initial
            HStack(alignment: .top) {
                Image(systemName: "building.columns.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Initial report")
                        .font(.headline)
                    
                    HStack(spacing: 40) {
                        ReportView(title: "Planned", amount: "0,00")
                        ReportView(title: "Engaged", amount: "0,00")
                        ReportView(title: "Executed", amount: "0,00")
                    }
                }
            }
            
            // Références Bancaires
            VStack(alignment: .leading) {
                Text("Bank references")
                    .font(.headline)
                
                BankReferenceView()
            }
            .padding()
//            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(width: 800, height: 600)
    }
}

// Vue pour le rapport initial (Planned, Engaged, Executed)
struct ReportView: View {
    var title: String
    var amount: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(amount)
                .font(.title3)
                .bold()
        }
    }
}

// Vue pour les références bancaires
struct BankReferenceView: View {
    @State private var bank = ""
    @State private var indicative = ""
    @State private var account = ""
    @State private var key = ""
    @State private var iban = ""
    @State private var bic = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bank")
                    .frame(width: 100, alignment: .leading)
                TextField("Bank", text: $bank)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            HStack {
                Text("Indicative")
                    .frame(width: 100, alignment: .leading)
                TextField("Indicative", text: $indicative)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Account")
                    .frame(width: 100, alignment: .leading)
                TextField("Account", text: $account)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Key")
                    .frame(width: 100, alignment: .leading)
                TextField("Key", text: $key)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("IBAN")
                    .frame(width: 100, alignment: .leading)
                TextField("IBAN", text: $iban)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            
            HStack {
                Text("BIC")
                    .frame(width: 100, alignment: .leading)
                TextField("BIC", text: $bic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
