//
//  BankView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

final class BanqueInfoManager: ObservableObject {
    @Published var account: EntityAccount?
    @Published var banqueInfo: EntityBanqueInfo?
}

struct BankView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var banqueManager: BanqueInfoManager

    @Query private var banqueInfos: [EntityBanqueInfo]
    
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
            if banqueManager.banqueInfo == nil {
                let account = CurrrentAccountManager.shared.getAccount()!
                banqueManager.account = account

                let newBanqueInfo = EntityBanqueInfo(account: account)
                banqueManager.banqueInfo = newBanqueInfo
                
                modelContext.insert(newBanqueInfo)
            }
        }
    }
}

struct SectionView: View {
    let title: String
    @Bindable var banqueInfo: EntityBanqueInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)

            if title == "Bank" {
                FieldView(label: String(localized :"Bank"), text: $banqueInfo.nomBanque)
                FieldView(label: String(localized :"Address"), text: $banqueInfo.adresse)
                FieldView(label: String(localized :"Complement"), text: $banqueInfo.complement)
                FieldView(label: String(localized :"CP"), text: $banqueInfo.codePostal)
                FieldView(label: String(localized :"Town"), text: $banqueInfo.ville)
            } else if title == "Contact" {
                FieldView(label: String(localized :"Name"), text: $banqueInfo.nomContact)
                FieldView(label: String(localized :"Function"), text: $banqueInfo.fonctionContact)
                FieldView(label: String(localized :"Phone"), text: $banqueInfo.telephoneContact)
            }
        }
        .padding()
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
                .frame(width: 300, alignment: .leading)

        }
    }
}


