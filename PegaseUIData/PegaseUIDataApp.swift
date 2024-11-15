//
//  PegaseUIDataApp.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 03/11/2024.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct PegaseUIDataApp: App {
    
    @StateObject private var windowSizeManager = WindowSizeManager()
    @Environment(\.modelContext) private var modelContext
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        ColorTransformer.register()
        setupForNilLibrary(modelContext: modelContext)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView100()
                .modelContainer(for: [
                    EntityAccount.self,
                    EntityBank.self,
                    EntityBankStatement.self,
                    EntityCarnetCheques.self,
                    EntityIdentity.self,
                    EntityInitAccount.self,
                    EntityPaymentMode.self,
                    EntityPreference.self,
                    EntityRubric.self,
                    EntitySchedule.self,
                    EntityTransactions.self
                ])
        }
    }
    
    func setupForNilLibrary(modelContext: ModelContext) {
        // Création de l'élément racine
        let root = EntityAccount()
        root.isRoot = true
        root.name = "Root"
        root.uuid = UUID()
        
        // Création des comptes
        let pierreAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Localizations.Document.IdName",
            idPrenom: "Localizations.Document.IdPrenom",
            numAccount: "00045700E",
            type: 0
        )
        
        let marieAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Martin",
            idPrenom: "Marie",
            numAccount: "00045701F",
            type: 0
        )
        
        let carteDeCredit1 = createAccount(
            name: "Carte_de_crédit",
            icon: "discount",
            idName: "Martin",
            idPrenom: "Pierre",
            numAccount: "00045702G",
            type: 1
        )
        
        let saving = createAccount(
            name: "Document.Save",
            icon: "icons8-money-box-80",
            idName: "Durand",
            idPrenom: "Jean",
            numAccount: "00045703H",
            type: 2
        )

        let jeanAccount = createAccount(
            name: "Current_account",
            icon: "icons8-museum-80",
            idName: "Durand",
            idPrenom: "Jean",
            numAccount: "00045704J",
            type: 0
        )
        
        // Création des en-têtes
        let header1 = createHeader(name: "BankAccount", parent: root)
        let header2 = createHeader(name: "BankAccount", parent: root)

        // Ajout des comptes aux en-têtes
        header1.children?.append(pierreAccount)
        header1.children?.append(marieAccount)
        header1.children?.append(carteDeCredit1)
        header1.children?.append(saving)

        header2.children?.append(jeanAccount)

        // Enregistrement des modifications
        do {
            if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let path = "Core Data SQLite file is located at: \(url.path)"
                print(path)
            }

            try modelContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error)")
        }
    }

    private func createAccount(name: String, icon: String, idName: String, idPrenom: String, numAccount: String, type: Int) -> EntityAccount {
        
        let account = EntityAccount()
        account.name = name
        account.nameImage = icon
        account .identity?.name = idName
        account.identity?.surName = idPrenom
        
        let initAccount = EntityInitAccount()
        initAccount.codeAccount = numAccount
        initAccount.account = account
        account.initAccount = initAccount
        
        account.type = type
        account.uuid = UUID()
        return account
    }
    
    private func createHeader(name: String, parent: EntityAccount) -> EntityAccount {
        let header = EntityAccount()
        header.isHeader = true
        header.name = name
        header.uuid = UUID()
        header.parent = parent
        return header
    }
}
class WindowSizeManager: NSObject, NSWindowDelegate, ObservableObject {
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            let size = window.frame.size
            UserDefaults.standard.set(size.width, forKey: "windowWidth")
            UserDefaults.standard.set(size.height, forKey: "windowHeight")
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct PegaseUIDataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        PegaseUIDataVersionedSchema.self,
    ]
    
    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct PegaseUIDataVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] = [
        EntityAccount.self,
    ]
}

func localizeString(_ key: String, comment: String = "") -> String {
    if #available(macOS 12, *) {
        return String(localized: String.LocalizationValue(key))
    } else {
        return NSLocalizedString(key, comment: comment)
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    func applicationShouldTerminateAfterLastWindowClosed (_ sender: NSApplication) -> Bool {
        return false
    }
}
