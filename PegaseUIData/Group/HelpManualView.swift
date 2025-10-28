import SwiftUI

struct HelpManualView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Database Manager",tableName: "Help")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(String(localized: "Application Manual",table: "Help"))
                    .font(.title2)
                    .foregroundColor(.secondary)
                Divider()

                Group {
                    Text(String(localized: "Purpose of the App", table: "Help"))
                        .font(.headline)
                    Text(String(localized: "This application lets you manage your people databases: create, open, edit, and view.", table: "Help"))
                }

                Group {
                    Text(String(localized:"Getting Started", table: "Help"))
                        .font(.headline)
                    Text("Intro2 : On launch, the welcome screen appears. \nFrom this screen, you can:\n- Create a new database (Create a new file)\n- Open an existing database (Open existing document…)\n- Open a sample project (Open sample document Project…)\n- Open a recent file (Recent files)", tableName: "Help")
                }

                Group {
                    Text(String(localized: "Create a New Database", table: "Help"))
                        .font(.headline)
                    Text("1. Click “Create a new file”.\n2. Choose a folder and a file name (the .store extension is recommended).\n3. Confirm: the database is created, a sample person is added, and the database opens.",tableName: "Help")
                }

                Group {
                    Text(String(localized: "Open an Existing Database",table: "Help"))
                        .font(.headline)
                    Text("- Welcome > “Open existing document…” and choose a .store file.\n- Or click an item in “Recent files”.\n- Or use the menu bar: File > “Open existing document…” (⇧⌘O).",tableName: "Help")
                }

                Group {
                    Text(String(localized:"Main Screen",table: "Help"))
                        .font(.headline)
                    Text("- The sidebar shows the database name and a “…” menu with:\n  • Close (close the database and return to the welcome screen)\n  • Show in Finder (reveal the .store file)\n- The main area shows the list of people (Table):\n  • Double-click a row to open the “Details” view.",tableName: "Help")
                }

                Group {
                    Text("Actions",tableName: "Help")
                        .font(.headline)
                         Text("- Add: opens a form to add a person.\n- Edit: select a person and edit it via the form.\n- Details: opens a detailed view for the selected person.\n- Delete: deletes the selected person (undoable).\n- Undo / Redo: undo/redo the last action (⌘Z / ⇧⌘Z).",tableName: "Help")
                }

                Group {
                    Text("Recent Files",tableName: "Help")
                        .font(.headline)
                         Text("- The “Recent files” list is available on the welcome screen.\n- Click: opens the database.\n- Right-click: Open, Show in Finder, Remove from list.",tableName: "Help")
                }

                Group {
                    Text("Tips",tableName: "Help")
                        .font(.headline)
                         Text("- Operations are saved automatically.\n- Use Undo/Redo to revert changes after a deletion or modification.\n- You can manage multiple databases and switch using “Recent files”.",tableName: "Help")
                }

                Group {
                    Text("Shortcuts",tableName: "Help")
                        .font(.headline)
                         Text("- Create New Document…: ⌘N\n- Open existing document…: ⇧⌘O\n- Undo: ⌘Z\n- Redo: ⇧⌘Z\n- Open Manual: ⌘?",tableName: "Help")
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

