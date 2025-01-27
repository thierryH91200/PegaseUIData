//  IdentyView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

final class IdentityInfoManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var identity: EntityIdentity? {
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

struct IdentyView: View {
    
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var identityInfoManager: IdentityInfoManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    
    @Query private var identityInfo: [EntityIdentity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identity")
                .font(.title)
                .padding(.bottom, 10)
                .accessibilityLabel("Identity title")

            if let account = currentAccountManager.currentAccount {
                Text("Current Account: \(account.name)")
            } else {
                Text("No account selected.")
            }

            VStack(alignment: .leading, spacing: 8) {
                
                if identityInfoManager.identity != nil {
                    SectionInfoView(identityInfo: identityInfoManager.identity!)
                }
            }
        }
        .padding()
        .frame(width: 600)
        .cornerRadius(10)
        .onAppear {
            
            if let account = currentAccountManager.currentAccount {
                identityInfoManager.currentAccount = account
            }

            // Créer un nouvel enregistrement si la base de données est vide
            if identityInfoManager.identity == nil {
                if let account = CurrentAccountManager.shared.getAccount() {
                    identityInfoManager.currentAccount = account
                } else {
                    print("Aucun compte disponible.")
                }
                IdentityManager.shared.configure(with: modelContext)
                let identity = IdentityManager.shared.getAllDatas()
                identityInfoManager.identity = identity

                if identity == nil {
                    
                    let newIdentityInfo = EntityIdentity()
                    identityInfoManager.identity = newIdentityInfo
                    modelContext.insert(newIdentityInfo)
                }
            }
        }
        .onDisappear {
            saveChanges()
            identityInfoManager.saveChanges(using: modelContext)
            identityInfoManager.identity = nil
        }
        .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
            
//            print("currentAccountManager.currentAccount changed to: \(String(describing: newAccount))")

            if let account = newAccount {
                identityInfoManager.identity = nil
                identityInfoManager.currentAccount = account
                
                loadOrCreateIdentity(for: account)
            }
        }

        .onChange(of: identityInfoManager.identity) { old , _ in
            do {
                try modelContext.save()
            } catch {
                print("Erreur lors de la sauvegarde : \(error)")
            }
        }
    }
    
    private func loadOrCreateIdentity(for account: EntityAccount) {
        
        IdentityManager.shared.configure(with: modelContext)
        if let existingIdentity = IdentityManager.shared.getAllDatas() {
            identityInfoManager.identity = existingIdentity
        } else {
            let newIdentity = EntityIdentity()
            newIdentity.account = account
            modelContext.insert(newIdentity)
            identityInfoManager.identity = newIdentity
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

struct SectionInfoView: View {
    
    @Environment(\.modelContext) var modelContext
    @Bindable var identityInfo: EntityIdentity
        
    var body: some View {
        HStack {
            Text("Name")
                .frame(width: 100, alignment: .leading)
            TextField("Name", text: $identityInfo.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Spacer()
            Text("Surname")
                .frame(width: 100, alignment: .leading)
            TextField("Surname", text: $identityInfo.surName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("Address")
                .frame(width: 100, alignment: .leading)
            TextField("Address", text: $identityInfo.adress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("Complement")
                .frame(width: 100, alignment: .leading)
            TextField("Complement", text: $identityInfo.complement)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("CP")
                .frame(width: 100, alignment: .leading)
            TextField("Postal Code", text: $identityInfo.cp)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)

            Spacer()
            Text("Town")
                .frame(width: 100, alignment: .leading)
            TextField("Town", text: $identityInfo.town)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("Country")
                .frame(width: 100, alignment: .leading)
            TextField("Country", text: $identityInfo.country)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Text("Phone")
                .frame(width: 100, alignment: .leading)
            TextField("Phone", text: $identityInfo.phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)

            Spacer()
            Text("Mobile")
                .frame(width: 100, alignment: .leading)
            TextField("Mobile", text: $identityInfo.mobile)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
        }
        HStack {
            Text("Email")
                .frame(width: 100, alignment: .leading)
            TextField("Email", text: $identityInfo.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .onChange(of: identityInfo) {old, _ in saveChanges() }
        Spacer()
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

}

