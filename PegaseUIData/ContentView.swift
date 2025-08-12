
//
//  ContentView.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState

//    @Query(sort: [SortDescriptor(\Item.number, order: .forward)]) private var items: [Item]

    var body: some View {
        VStack {
            Text("Main window is open ✅")
//            Text("Items count: \(items.count)")
            List {
//                ForEach(items) { item in
//                    HStack {
//                        Text(item.number.map { "N°\($0)" } ?? "—")
//                        Text(item.timestamp.formatted(date: .numeric, time: .shortened))
//                        Spacer()
//                    }
//                }
            }
            Button("Add Item") {
                addItem()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .onAppear {
            activateMainWindow()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    appState.isProjectOpen = false // Revenir à WelcomeWindowView
                } label: {
                    Label("Home", systemImage: "house")
                }
            }
        }

    }

    // MARK: - Private Methods

    private func addItem() {
        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//            do {
//                try modelContext.save()
//                print("✅ Item added and saved")
//            } catch {
//                print("❌ Error during save:", error)
//            }
        }
    }
    
    private func activateMainWindow() {
        if let window = NSApp.windows.first(where: { $0.isVisible && $0.title == "Main Project Window" }) {
            window.makeKeyAndOrderFront(nil)
            window.makeMain()
            NSApp.activate(ignoringOtherApps: true)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.mainWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - View Extension
extension View {
    func getHostingWindow(completion: @escaping (NSWindow?) -> Void) -> some View {
        background(WindowAccessor(callback: completion))
    }
}
