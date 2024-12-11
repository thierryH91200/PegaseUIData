//
//  BankView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

struct BankView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var banqueInfos: [BanqueInfo]
    
    var account: EntityAccount?
    @State var currentAccount: EntityAccount?
    
    var body: some View {
        VStack(spacing: 30) {
            if let banqueInfo = banqueInfos.first {
                // Utilisez un Binding pour mettre à jour les données en direct
                SectionView(title: "Bank", banqueInfo: banqueInfo)
                SectionView(title: "Contact", banqueInfo: banqueInfo)
            } else {
                Text("No bank information available")
            }
        }
        .padding()
        .onAppear {
            // Créer un nouvel enregistrement si la base de données est vide
            if banqueInfos.isEmpty {
                let context = modelContext
                let newBanqueInfo = BanqueInfo(account: currentAccount!)
                context.insert(newBanqueInfo)
            }
        }
    }
}

struct SectionView: View {
    let title: String
    @Bindable var banqueInfo: BanqueInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)

            if title == "Bank" {
                FieldView(label: "Bank", text: $banqueInfo.nomBanque)
                FieldView(label: "Adress", text: $banqueInfo.adresse)
                FieldView(label: "Complement", text: $banqueInfo.complement)
                FieldView(label: "CP", text: $banqueInfo.codePostal)
                FieldView(label: "Town", text: $banqueInfo.ville)
            } else if title == "Contact" {
                FieldView(label: "Name", text: $banqueInfo.nomContact)
                FieldView(label: "Fonction", text: $banqueInfo.fonctionContact)
                FieldView(label: "Phone", text: $banqueInfo.telephoneContact)
            }
        }
        .padding()
//        .background(Color.gray)
        .cornerRadius(8)
    }
}

struct FieldView: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}


