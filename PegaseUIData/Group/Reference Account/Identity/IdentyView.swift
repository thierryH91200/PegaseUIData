//  IdentyView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

final class IdentityInfoManager: ObservableObject {
    @Published var account: EntityAccount?
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
    
//    var account = CurrrentAccountManager.shared.getAccount()!

    @Query private var identityInfo: [EntityIdentity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identity")
                .font(.title)
                .padding(.bottom, 10)
            
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
            // Créer un nouvel enregistrement si la base de données est vide
            if identityInfoManager.identity == nil {
                let account = CurrrentAccountManager.shared.getAccount()!
                identityInfoManager.account = account

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
        }
        .onChange(of: identityInfoManager.identity) { old , _ in
            do {
                try modelContext.save()
            } catch {
                print("Erreur lors de la sauvegarde : \(error)")
            }
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
                .onSubmit {
                    saveChanges()
                }

            Spacer()
            Text("Surname")
                .frame(width: 100, alignment: .leading)
            TextField("Surname", text: $identityInfo.surName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    saveChanges()
                }
        }
        
        HStack {
            Text("Address")
                .frame(width: 100, alignment: .leading)
            TextField("Address", text: $identityInfo.adress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    saveChanges()
                }
        }
        
        HStack {
            Text("Complement")
                .frame(width: 100, alignment: .leading)
            TextField("Complement", text: $identityInfo.complement)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    saveChanges()
                }

        }
        
        HStack {
            Text("CP")
                .frame(width: 100, alignment: .leading)
            TextField("Postal Code", text: $identityInfo.cp)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .onSubmit {
                    saveChanges()
                }

            Spacer()
            Text("Town")
                .frame(width: 100, alignment: .leading)
            TextField("Town", text: $identityInfo.town)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    saveChanges()
                }

        }
        
        HStack {
            Text("Country")
                .frame(width: 100, alignment: .leading)
            TextField("Country", text: $identityInfo.country)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    saveChanges()
                }
        }
        
        HStack {
            Text("Phone")
                .frame(width: 100, alignment: .leading)
            TextField("Phone", text: $identityInfo.phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
                .onSubmit {
                    saveChanges()
                }

            Spacer()
            Text("Mobile")
                .frame(width: 100, alignment: .leading)
            TextField("Mobile", text: $identityInfo.mobile)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 150)
                .onSubmit {
                    saveChanges()
                }

        }
        HStack {
            Text("Email")
                .frame(width: 100, alignment: .leading)
            TextField("Email", text: $identityInfo.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
