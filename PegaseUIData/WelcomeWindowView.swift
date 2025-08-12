//
//  WelcomeWindowView.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import SwiftUI
import SwiftData


struct WelcomeWindowView: View {
    @ObservedObject var recentManager: RecentProjectsManager
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    var openHandler: (URL) -> Void
    var onCreateProject: () -> Void
    
    @State private var window: NSWindow?
    @State private var showCreateSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            LeftPanelView(
                onCreateProject: onCreateProject,
                openHandler: openHandler,
            )
            .environmentObject(appState)
            .environmentObject(recentManager)

            Divider()
            
            RecentProjectsListView(
                recentManager: recentManager,
                openHandler: openHandler
            )
            .environmentObject(appState)
        }
        .frame(width: 700, height: 400)
        .getHostingWindow { self.window = $0 }
    }
}

private struct LeftPanelView: View {
    @Environment(\.modelContext) private var modelContext
    var onCreateProject: () -> Void
    var openHandler: (URL) -> Void
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recentManager: RecentProjectsManager
    @EnvironmentObject var projectCreationManager: ProjectCreationManager
    
    @State private var showCreateSheet = false
    @State private var showResetAlert = false
    
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "hammer.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            
            Text("WelcomeTo")
                .font(.largeTitle)
                .bold()
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))")
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Button("Create New Document...") {
                    showCreateSheet = true
                }

                Button("Open existing document...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    panel.allowedContentTypes = [.sqlite, .store]
                    if panel.runModal() == .OK, let url = panel.url {
                        openHandler(url)
                        recentManager.addProject(with: url)
                        appState.isProjectOpen = true
                    }
                }
                
                Button("Open sample document Project...") {
                    onCreateProject()
                }
                
                Button("Réinitialiser préférences…") {
                    showResetAlert = true
                }
                .foregroundColor(.red)
                .alert("Confirmer la réinitialisation ?", isPresented: $showResetAlert) {
                    Button("Annuler", role: .cancel) {}
                    Button("Réinitialiser", role: .destructive) {
                        if let appDomain = Bundle.main.bundleIdentifier {
                            UserDefaults.standard.removePersistentDomain(forName: appDomain)
                            UserDefaults.standard.synchronize()
                        }
                    }
                } message: {
                    Text("Cette opération supprimera toutes les préférences de l'application.")
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateProjectView { projectName in
                projectCreationManager.createDatabase(named: projectName)
            }
        }
        
        .frame(maxWidth: .infinity)
        .padding()
    }
//    private func createDatabase(named projectName: String) -> URL? {
//        projectCreationManager.createDatabase(named: projectName)
//    }
}

private struct RecentProjectsListView: View {
    @ObservedObject var recentManager: RecentProjectsManager
    var openHandler: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Projects")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(recentManager.projects, id: \.id) { project in
                    RecentProjectRowView(
                        project: project,
                        onOpen: openHandler,
                        onDelete: {
                            recentManager.removeProject(project)
                        }
                    )
                }
            }
            .frame(width: 350, height: 300)
            .listStyle(.inset)
            .padding(.horizontal)
        }
        .frame(width: 400)
    }
}

private struct RecentProjectRowView: View {
    let project: RecentProject
    let onOpen: (URL) -> Void
    let onDelete: () -> Void
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cylinder.split.1x2.fill")
                .foregroundColor(.accentColor)
                .imageScale(.large)
            
            VStack(alignment: .leading, spacing: 2) {
                // Nom du projet
                Text(project.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                // Chemin avec tilde
                Text((project.url.path as NSString).abbreviatingWithTildeInPath)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen(project.url)
            appState.isProjectOpen = true
        }
    }
}

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recentManager: RecentProjectsManager

    @State private var projectName: String = "Project without a Name"
    static let numberKey = "ItemLastNumber"
    var onCreate: (String) -> URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New project")
                .font(.headline)
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            
            HStack {
                Button("Cancel") {
                    appState.isProjectOpen = false
                    dismiss()
                }
                Button("Create") {
                    let name = projectName.isEmpty ? "Project Without a Name" : projectName
                    if let url = onCreate(name) {
                        recentManager.addProject(with: url)
                        UserDefaults.standard.set(0, forKey: Self.numberKey)

                        appState.isProjectOpen = true
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

