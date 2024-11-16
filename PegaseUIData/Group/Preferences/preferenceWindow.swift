//
//  prefCont.swift
//  testPref
//
//  Created by Thierry hentic on 04/11/2024.
//

import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    
    private init() {
        // Créer la fenêtre de préférences avec SwiftUI comme contenu
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 400, height: 300))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false // Garde la fenêtre en mémoire après la fermeture
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // Met l'application au premier plan
    }
    
    func windowWillClose(_ notification: Notification) {
        // Assurez-vous que les changements sont sauvegardés si besoin
    }
}


struct PreferencesView: View {
    @AppStorage("showNotifications") private var showNotifications = false
    @AppStorage("enableSounds") private var enableSounds = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Show notifications", isOn: $showNotifications)
            Toggle("Enable sounds", isOn: $enableSounds)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
