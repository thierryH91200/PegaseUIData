//  IdentyView.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData

struct IdentyView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var identityInfo: [EntityIdentity]
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identity")
                .font(.title)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                
                if let identityInfo = identityInfo.first {
                    SectionInfoView(identityInfo: identityInfo)
                }
            }
        }
        .padding()
        .frame(width: 600)
//        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .onAppear {
            // Créer un nouvel enregistrement si la base de données est vide
            if identityInfo.isEmpty {
                let context = modelContext
                let newIdentityInfo = EntityIdentity()
                context.insert(newIdentityInfo)
            }
        }
        
    }
}

struct SectionInfoView: View {
    
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
            TextField("Postal Code", text: $identityInfo.town)
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
    }
}
