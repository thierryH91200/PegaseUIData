//  ProjectCreationManager.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import Foundation
import SwiftData
import Combine


final class ProjectCreationManager: ObservableObject {
    @MainActor func createDatabase(named projectName: String) -> URL? {
        
        let schema = AppGlobals.shared.schema

        let documentsURL = URL.documentsDirectory
        let newDirectory = documentsURL.appendingPathComponent(projectName)
        do {
            try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true)
            let storeURL = newDirectory.appendingPathComponent("\(projectName).store")
            let configuration = ModelConfiguration(url: storeURL)
            
            let container = try ModelContainer(for: schema, configurations: configuration)
            
            DataContext.shared.context = container.mainContext
            InitManager.shared.initialize()
            print("✅ Base créée : \(storeURL.path)")
            
            return storeURL
        } catch {
            print("❌ Erreur création base : \(error)")
            return nil
        }
    }
}
