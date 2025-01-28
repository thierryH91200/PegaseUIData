//
//  BankView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

final class BanqueInfoManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var banqueInfo: EntityBanqueInfo? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    func saveChanges(using context: ModelContext? = nil) {
        guard let context = context else { return }
        
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde des modifications : \(error)")
        }
    }
}

struct BankView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var banqueInfoManager: BanqueInfoManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager

    @Query private var banqueInfos: [EntityBanqueInfo]
    
    var body: some View {
        VStack(spacing: 30) {
            if let banqueInfo = banqueInfoManager.banqueInfo {
                // Utilisez un Binding pour mettre à jour les données en direct
                SectionView(title: "Bank", banqueInfo: banqueInfo)
                SectionView(title: "Contact", banqueInfo: banqueInfo)
                Spacer()
            } else {
                Text("No bank information available")
            }
        }
        .padding()
        .onAppear {
            if let account = currentAccountManager.currentAccount {
                banqueInfoManager.currentAccount = account
            }

            // Créer un nouvel enregistrement si la base de données est vide
            if banqueInfoManager.banqueInfo == nil {
                if let account = CurrentAccountManager.shared.getAccount() {
                    banqueInfoManager.currentAccount = account
                } else {
                    print("Aucun compte disponible.")
                }
                BankManager.shared.configure(with: modelContext)
                let banqueInfo = BankManager.shared.getAllDatas()
                banqueInfoManager.banqueInfo = banqueInfo

                if banqueInfo == nil {
                    
                    let newbanqueInfo = EntityBanqueInfo()
                    banqueInfoManager.banqueInfo = newbanqueInfo
                    modelContext.insert(newbanqueInfo)
                }
            }
        }
        .onDisappear {
            saveChanges()
            banqueInfoManager.saveChanges(using: modelContext)
            banqueInfoManager.banqueInfo = nil
        }

        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            
//            print("currentAccountManager.currentAccount changed to: \(String(describing: newAccount))")

            if let account = newAccount {
                banqueInfoManager.banqueInfo = nil
                banqueInfoManager.currentAccount = account
                
                loadOrCreateBank(for: account)
            }
        }
        .onChange(of: banqueInfoManager.banqueInfo) { old , _ in
            do {
                try modelContext.save()
            } catch {
                print("Erreur lors de la sauvegarde : \(error)")
            }
        }
    }
    
    private func loadOrCreateBank(for account: EntityAccount) {
        
        BankManager.shared.configure(with: modelContext)
        if let existingBanque = BankManager.shared.getAllDatas() {
            banqueInfoManager.banqueInfo = existingBanque
        } else {
            let newBanqueInfo = EntityBanqueInfo()
            newBanqueInfo.account = account
            modelContext.insert(newBanqueInfo)
            banqueInfoManager.banqueInfo = newBanqueInfo
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
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
                FieldView(label: String(localized :"CP"), text: $banqueInfo.cp)
                FieldView(label: String(localized :"Town"), text: $banqueInfo.town)
            } else if title == "Contact" {
                FieldView(label: String(localized :"Name"), text: $banqueInfo.name)
                FieldView(label: String(localized :"Function"), text: $banqueInfo.fonction)
                FieldView(label: String(localized :"Phone"), text: $banqueInfo.phone)
            }
        }
        .padding()
        .cornerRadius(8)
    }
}

struct FieldView: View {
    
    @Environment(\.modelContext) var modelContext

    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300, alignment: .leading)
                .onSubmit {
                    saveChanges()
                }

        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

}


