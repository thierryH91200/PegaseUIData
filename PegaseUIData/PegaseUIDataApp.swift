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
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var windowSizeManager = WindowSizeManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) var undoManager

    @StateObject private var appState = AppState()
    @StateObject private var recentManager = RecentProjectsManager() // ← ici
    @StateObject private var projectCreationManager = ProjectCreationManager()
    @State private var dataController: DataController
    var modelContainer: ModelContainer

    let schema = AppGlobals.shared.schema
    let folder = "PegaseUIDataBDD"
    let file = "PegaseUIData.store"

    init() {
        ColorTransformer.register()
        
        do {
            let documentsURL = URL.documentsDirectory
            let directory = documentsURL.appendingPathComponent(folder)
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            let storeURL = directory.appendingPathComponent(file)
            let config = ModelConfiguration(url: storeURL)

            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContainer.mainContext.undoManager = UndoManager()
            
            // ⚠️ Initialisation de la propriété temporaire
            dataController = DataController(url: storeURL)

        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }
    
    @State private var loadDemoTrigger = false
    @State private var resetTrigger = false

    var body: some Scene {
        
//        Window("Pegase", id: "main") {
        WindowGroup {
            
            if appState.isProjectOpen == true {
                ContentView100()
                    .frame(minWidth: 800, minHeight: 600) // Exemple de taille
                    .environment(\.modelContext, dataController.modelContainer.mainContext)
                    .environmentObject(appState)
            } else {
                
                WelcomeWindowView(
                    recentManager: recentManager, openHandler: { url in
                        let project = RecentProject(name: url.lastPathComponent, url: url)
                        recentManager.addProject(project)
                        dataController = DataController(url: url)
                    },
                    onCreateProject: {
                        createProject()
                        appState.isProjectOpen = true
                    }
                )
                .environment(\.modelContext, modelContainer.mainContext)
                .environmentObject(appState)
                .environmentObject(recentManager)
                // Injection of projectCreationManager environment object
                .environmentObject(projectCreationManager)


//            SplashScreenView( )
//                .onChange(of: loadDemoTrigger) { _, newValue in
//                    if newValue {
//                        NotificationCenter.default.post(name: .loadDemoRequested, object: nil)
//                        loadDemoTrigger = false
//                    }
//                }
//                .onChange(of: resetTrigger) { _, newValue in
//                    if newValue {
//                        NotificationCenter.default.post(name: .resetDatabaseRequested, object: nil)
//                        resetTrigger = false
//                    }
                }
        }
        .commands {
            DemoDataCommand(
                loadDemoAction: { loadDemoTrigger = true },
                resetAction: { resetTrigger = true }
            )
        }
        
        .commands {
            CommandGroup(after: .newItem) {
                Divider() // Cela n’aura pas d’effet visible ici, mais utile à noter
            }

            CommandGroup(after: .newItem) {
                Menu("Import") { // Création d'un menu "Import"
                    Button("Transaction CSV") {
                        NotificationCenter.default.post(name: .importTransaction, object: nil)
                    }
                    .keyboardShortcut("T", modifiers: [.command, .shift]) // Cmd+Shift+T
                    
                    Button("Transaction OFX") {
                        NotificationCenter.default.post(name: .importTransactionOFX, object: nil)
                    }
                    .keyboardShortcut("O", modifiers: [.command, .shift]) // Cmd+Shift+O

                    Button("Statement") {
                        NotificationCenter.default.post(name: .importReleve, object: nil)
                    }
                    .keyboardShortcut("R", modifiers: [.command, .shift]) // Cmd+Shift+R
                }
                Menu("Export") {    // Création d'un menu "Export"
                    Button("Transaction CSV") {
                        NotificationCenter.default.post(name: .exportTransactionCSV, object: nil)
                    }
                    .keyboardShortcut("E", modifiers: [.command, .shift]) // Cmd+Shift+E
                    
                    Button("Transaction OFX") {
                        NotificationCenter.default.post(name: .exportTransactionOFX, object: nil)
                    }
                    .keyboardShortcut("E", modifiers: [.command, .shift]) // Cmd+Shift+E

                    Button("Statement") {
                        NotificationCenter.default.post(name: .exportReleve, object: nil)
                    }
                    .keyboardShortcut("S", modifiers: [.command, .shift]) // Cmd+Shift+S
                }
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    PreferencesWindowController.shared.showWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .modelContainer(modelContainer)
    }
    
    private func defaultStoreURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsURL.appendingPathComponent("default.store")
        print(storeURL)
        return storeURL
    }
    
    func createProject() {
        // 1. Demander un nom à l’utilisateur
        let alert = NSAlert()
        alert.messageText = String(localized:"Project Name")
        alert.informativeText = String(localized:"Enter the name of your new database :")
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized:"Cancel"))
        alert.addButton(withTitle: String(localized:"OK"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "MonProjet"
        alert.accessoryView = textField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return } // Annuler
        let projectName = textField.stringValue.isEmpty ? "ProjetSansNom" : textField.stringValue

        // 2. Construire l'URL avec le nom choisi
        let documentsURL = URL.documentsDirectory
        let newDirectory = documentsURL.appendingPathComponent(projectName)
        do {
            try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Erreur création dossier : \(error)")
            return
        }

        let storeURL = newDirectory.appendingPathComponent("\(projectName).store")

        // 3. Créer la base SwiftData avec ce nom
        do {
            let configuration = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: schema, configurations: configuration)

            // Exemple d'insertion d’un élément de test
            DataContext.shared.context = container.mainContext
            InitManager.shared.initialize()

            let project = RecentProject(name: storeURL.lastPathComponent, url: storeURL)
            recentManager.addProject(project)
            
            print("✅ Base créée : \(storeURL.path)")
        } catch {
            print("❌ Erreur création base : \(error)")
        }
    }
}

class WindowSizeManager: NSObject, NSWindowDelegate, ObservableObject {
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            let size = window.frame.size
            UserDefaults.standard.set(size.width,  forKey: "windowWidth")
            UserDefaults.standard.set(size.height, forKey: "windowHeight")
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

extension UTType {
    static var flashCards = UTType(exportedAs: "com.example.item-document")
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


@Observable
@MainActor
final class DataController {
    var modelContainer: ModelContainer
    
    let schema = AppGlobals.shared.schema

    init(url: URL) {
        let config = ModelConfiguration(url: url)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: config)
            self.modelContainer.mainContext.undoManager = UndoManager()
        } catch {
            fatalError("❌ Failed to create model container: \(error)")
        }
    }
}

final class AppGlobals {
    static let shared = AppGlobals()
    
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
        EntityStatus.self,
        EntityPreference.self,
        EntityRubric.self,
        EntitySchedule.self,
        EntitySousOperation.self,
        EntityTransaction.self
    ])

    private init() {}
}

