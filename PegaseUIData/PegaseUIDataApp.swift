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
    
    var container: ModelContainer

    let schema = Schema([
        EntityAccount.self,
        EntityBankStatement.self,
        EntityBanqueInfo.self,
        EntityCategory.self,
        EntityCheckBook.self,
        EntityFolderAccount.self,
        EntityIdentity.self,
        EntityInitAccount.self,
        EntityPaymentMode.self,
        EntityPreference.self,
        EntityRubric.self,
        EntitySchedule.self,
        EntitySousOperations.self,
        EntityTransactions.self
    ])

    init() {
        ColorTransformer.register()
        
        do {
            let storeURL = URL.documentsDirectory.appending(path: "PegaseUIData.store")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }
    
    var body: some Scene {
        Window("Storm Viewer", id: "main") {
//        WindowGroup {
            ContentView100()
        }
        .modelContainer(container)
    }
    
    private func defaultStoreURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsURL.appendingPathComponent("default.store")
        print(storeURL)
        return storeURL
    }
}

extension ModelConfiguration {
    static func defaultConfiguration(at url: URL) -> ModelConfiguration {
        ModelConfiguration( url: url )
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
