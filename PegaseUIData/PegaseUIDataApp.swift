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
    
}

func ModelConfiguration() {
    let modelContainer: ModelContainer
    // Set up default location in Application Support directory
    let fileManager = FileManager.default
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directoryURL = appSupportURL.appendingPathComponent("Example")
    
    // Set the path to the name of the store you want to set up
    let fileURL = directoryURL.appendingPathComponent("Example.store")
    
    // Create a schema for your model (**Item 1**)
    let schema = Schema([EntityAccount.self])
    
    do {
        // This next line will create a new directory called Example in Application Support if one doesn't already exist, and will do nothing if one already exists, so we have a valid place to put our store
        try fileManager.createDirectory (at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        // Create our `ModelConfiguration` (**Item 3**)
        let defaultConfiguration = ModelConfiguration("EntityAccount", schema: schema, url: fileURL)
        
        do {
            // Create our `ModelContainer`
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: PegaseUIDataMigrationPlan.self,
                configurations: defaultConfiguration
            )
         } catch {
            fatalError("Could not initialise the container…")
        }
    } catch {
        fatalError("Could not find/create Example folder in Application Support")
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
