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
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            EyesSettingsView()
                .tabItem {
                    Label("Eyes", systemImage: "eye")
                }
        }
        .padding()
        .frame(width: 450, height: 250) // Taille de la fenêtre de préférences
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Launch at login", isOn: .constant(true))
            Toggle("Show in menu bar (hide from Dock)", isOn: .constant(false))
            
            Spacer()
        }
        .padding()
    }
}

struct EyesSettingsView: View {
    @AppStorage("foregroundColor") private var foregroundColorHex: String = "#000000"
    @AppStorage("backgroundColor") private var backgroundColorHex: String = "#00FF00"
    @AppStorage("alphaValue") private var alphaValue: Double = 1.0

    private var foregroundColor: Binding<Color> {
        Binding(
            get: { Color(hex: foregroundColorHex) },
            set: { foregroundColorHex = $0.toHex() }
        )
    }

    private var backgroundColor: Binding<Color> {
        Binding(
            get: { Color(hex: backgroundColorHex) },
            set: { backgroundColorHex = $0.toHex() }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Foreground color:")
                    .frame(width: 150, alignment: .leading)
                ColorPicker("", selection: foregroundColor)
                    .labelsHidden()
            }
            HStack {
                Text("Background color:")
                    .frame(width: 150, alignment: .leading)
                ColorPicker("", selection: backgroundColor)
                    .labelsHidden()
            }
            HStack {
                Text("Alpha value:")
                    .frame(width: 150, alignment: .leading)
                Slider(value: $alphaValue, in: 0...1)
            }
            
            Spacer()
        }
        .padding()
    }
}
