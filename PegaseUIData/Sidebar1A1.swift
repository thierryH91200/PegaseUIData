//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by thierryH24 on 15/11/2025.
//

import SwiftUI
import SwiftData
import AppKit
import Combine

struct IconItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
}

struct AccountFormView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    let account: EntityAccount?
    
    @State private var selectedImageName: String = ""

    @State var nameAccount: String = ""
    @State var nameIcon: String = ""
    @State var name: String = ""
    @State var surName: String = ""
    @State var solde: String = ""
    @State var codeAccount: String = ""
    
    @State private var showIconPicker = false
    @State private var selectedIconName: String? = nil

    let icons: [IconItem] = [
        IconItem(title: "Bank",        imageName: "icons8-museum-80"),
        IconItem(title: "Safe",        imageName: "icons8-money-box-80"),
        IconItem(title: "Money",       imageName: "icons8-money-100"),
        IconItem(title: "Expensive",   imageName: "icons8-expensive-100"),
        IconItem(title: "Purse",       imageName: "icons8-purse-100"),
        IconItem(title: "Wallet",      imageName: "icons8-wallet-80"),
        IconItem(title: "Safe",        imageName: "icons8-safe-100"),
        IconItem(title: "Card",        imageName: "discount"),
        IconItem(title: "PayPal",      imageName: "icons8-paypal-100"),
    ]

       
    var body: some View {
        Text("AccountFormView")
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
        
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Text(String(localized:"Name Account", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $nameAccount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Choose an icon") { showIconPicker = true }

                }
                HStack(spacing: 20) {
                    Text(String(localized:"Name", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Surname", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $surName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Balance", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $solde)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Account number", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $codeAccount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Text(String(localized:"Name Icon : \(selectedIconName ?? "none")", table: "Setting"))
                        .frame(width: 100, alignment: .leading)

                    if let name = selectedIconName {
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
        .sheet(isPresented: $showIconPicker) {
            IconPickerGrid(icons: icons, selectedImage: $selectedIconName) { name in
                selectedIconName = name
            }
        }

        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized:"Cancel", table: "Settings")) {
                    isPresented = false
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized:"Save", table: "Settings")) {
                    save()
                }
                .disabled(name.isEmpty )
                .opacity( name.isEmpty ? 0.6 : 1)
            }
        }
        .frame(width: 400)
        .onAppear {
            if let account = account {
                nameAccount = account.name
                nameIcon = account.nameIcon
                selectedIconName = account.nameIcon
                name = account.identity?.name ?? ""
                surName = account.identity?.surName ?? ""
                codeAccount = account.initAccount?.codeAccount ?? ""
            }
        }

        // Bandeau du bas
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
    }
    func save() {
        if isModeCreate { // Création
            _ = AccountManager.shared.create(
                nameAccount: nameAccount,
                nameImage: nameIcon,
                idName: name,
                idPrenom: surName,
                numAccount: codeAccount
            )
        } else { // Modification
            if let existingItem = account {
                existingItem.name = nameAccount
                existingItem.nameIcon = nameIcon
                existingItem.identity?.name = name
                existingItem.identity?.surName = surName
                existingItem.initAccount?.codeAccount = codeAccount

                AccountManager.shared.save()
            }
        }
        isPresented = false
        dismiss()
    }
}

struct IconPickerGrid: View {
    let icons: [IconItem]
    @Binding var selectedImage: String?
    var onSelect: ((String) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    let columns: [GridItem] = [
        GridItem(.flexible(minimum: 40), spacing: 0),
        GridItem(.flexible(minimum: 40), spacing: 0),
        GridItem(.flexible(minimum: 40), spacing: 0)
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Choose an icon")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(icons.prefix(9)) { icon in
                    VStack(spacing: 0) {
                        Image(icon.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding(0)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(selectedImage == icon.imageName ? 0.08 : 0))
                            )
                            .background(
                                Circle()
                                    .stroke(
                                        selectedImage == icon.imageName ? Color.accentColor : Color.clear,
                                        lineWidth: 3
                                    )
                            )

                        Text(icon.title)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedImage = icon.imageName
                        onSelect?(icon.imageName)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}


struct GroupAccountFormView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isPresented: Bool
    @Binding var isModeCreate: Bool
    
    let accountFolder: EntityFolderAccount?
    
    @State var name: String = ""
    @State var nameImage: String = ""
    
    var body: some View {
        Text("Group Account FormView")
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
        
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Text(String(localized:"Name", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack(spacing: 20) {
                    Text(String(localized:"Name Image", table: "Settings"))
                        .frame(width: 100, alignment: .leading)
                    TextField("", text: $nameImage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
            }
            
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized:"Cancel", table: "Settings")) {
                    isPresented = false
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized:"Save", table: "Settings")) {
                    isPresented = false
                    save()
                    dismiss()
                }
                .disabled(name.isEmpty )
                .opacity( name.isEmpty ? 0.6 : 1)
            }
        }
        .frame(width: 400)
        
        // Bandeau du bas
        Rectangle()
            .fill(isModeCreate ? Color.blue : Color.green)
            .frame(height: 10)
    }
    
    private func save() {
        if isModeCreate { // Création
            AccountFolderManager.shared.create(
                name: name,
                nameImage: nameImage)
        } else { // Modification
            if let existingItem = accountFolder {
                existingItem.name = name
                existingItem.nameImage = nameImage
                AccountFolderManager.shared.save()
            }
        }
        isPresented = false
        dismiss()
    }
}

