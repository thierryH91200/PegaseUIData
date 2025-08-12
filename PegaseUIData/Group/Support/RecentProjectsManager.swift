//
//  RecentProjectsManager.swift
//  WelcomeTo
//
//  Created by thierryH24 on 06/08/2025.
//

import Foundation
import Combine // nécessaire pour ObservableObject et @Published


struct RecentProject: Identifiable, Hashable, Codable {
    var id: UUID
    let name: String
    let url: URL
    
    // Optionnel : constructeur pratique
    init(id: UUID = UUID(), name: String, url: URL) {
        self.id = id
        self.name = name
        self.url = url
    }
}

protocol RecentProjectsProviding {
    var projects: [RecentProject] { get }
 
    func load()
    func save()

    func addProject(_ project: RecentProject)
    func addProject(with url: URL)
    
    func removeProject(_ project: RecentProject)
    func removeProject(at offsets: IndexSet)
}

class RecentProjectsManager: ObservableObject,  Identifiable , RecentProjectsProviding {
    @Published var projects: [RecentProject] = []
    
    private let key = "RecentProjects"
    private let maxRecentProjects = 20
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RecentProject].self, from: data) {
            
            // Garde uniquement les projets dont le fichier existe
            projects = decoded.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            
            // Enregistre de nouveau si certains projets ont été supprimés
            save()
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func addProject(_ project: RecentProject) {
        
        // Supprime les doublons basés sur l'URL
        projects.removeAll { $0.url == project.url }
        
        // Ajoute le projet en haut de la liste
        projects.insert(project, at: 0)
        
        // Limite à maxRecentProjects éléments
        if projects.count > maxRecentProjects {
            projects = Array(projects.prefix(20))
        }
        save()
    }
    
    func addProject(with url: URL) {
        let project = RecentProject(name: url.lastPathComponent, url: url)
        addProject(project)
    }
    
    // Suppression d’un projet
    func removeProject(_ project: RecentProject) {
        projects.removeAll { $0.id == project.id }
        save()
    }
    
    // Suppression par index (optionnel)
    func removeProject(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { // Supprimer dans l'ordre inverse pour éviter les erreurs d'index
            projects.remove(at: index)
        }
        save()
    }
}
