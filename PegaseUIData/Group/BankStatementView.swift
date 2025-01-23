//
//  BankStatementView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import SwiftData
import PDFKit

struct BankStatementView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        BankStatementTableView()
            .padding()
            .task {
                await performFalseTask()
            }
    }
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

struct BankStatementTableView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var statements: [EntityBankStatement] = []
    @State private var selectedStatement: EntityBankStatement? // Sélectionne l'entité complète
    @State private var isEditing: Bool = false
    @State private var showEditSheet: Bool = false
    
    var body: some View {
        VStack {
            Table(statements, selection: $selectedStatement.bindingId(from: statements)) {
                TableColumn("Num") { statement in
                    Text("\(statement.num)")
                }
                TableColumn("Start Date") { statement in
                    Text(statement.startDate, style: .date)
                }
                TableColumn("Solde Init") { statement in
                    Text("\(statement.startSolde, specifier: "%.2f") €")
                }
                TableColumn("Date inter") { statement in
                    Text(statement.interDate, style: .date)
                }
                TableColumn("Solde inter") { statement in
                    Text("\(statement.interSolde, specifier: "%.2f") €")
                }
                TableColumn("End Date") { statement in
                    Text(statement.endDate, style: .date)
                }
                TableColumn("Solde fin") { statement in
                    Text("\(statement.endSolde, specifier: "%.2f") €")
                }
                TableColumn("CB Date") { statement in
                    Text(statement.cbDate, style: .date)
                }
                TableColumn("CB Balance") { statement in
                    Text("\(statement.cbSolde, specifier: "%.2f") €")
                }
                TableColumn("PDF") { statement in
                    Text(statement.pdfLink)
                }
            }
            .frame(height: 300)
            HStack {
                // Bouton pour ajouter un enregistrement
                Button(action: {
                    isEditing = false
                    showEditSheet = true
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Bouton pour modifier un enregistrement
                Button(action: {
                    isEditing = true
                    showEditSheet = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Bouton pour supprimer un enregistrement
                Button(action: {
                    delete(selectedStatement!)
                }) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                Spacer()
            }
            .contextMenu {
                Button("Add") {
                    isEditing = false
                    showEditSheet = true
                }
                if let selected = selectedStatement {
                    Button("Edit") {
                        isEditing = true
                        showEditSheet = true
                    }
                    Button("Delete") {
                        delete(selected)
                    }
                }
            }
            .onAppear {
                fetchData()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditBankStatementView(statement: $selectedStatement, isEditing: isEditing)
        }
    }
    
    private func fetchData() {
        guard let account = BankStatementManager.shared.currentAccount else { return }
        statements = BankStatementManager.shared.getAllDatas(for: account)
    }
    
    private func delete(_ statement: EntityBankStatement) {
        BankStatementManager.shared.remove(entity: statement)
        fetchData()
    }
}

// MARK: - Extension pour Binding sur ID

extension Binding where Value == EntityBankStatement? {
    /// Permet de transformer un `Binding<EntityBankStatement?>` en un `Binding<ID?>` pour les Tables
    func bindingId(from statements: [EntityBankStatement]) -> Binding<EntityBankStatement.ID?> {
        Binding<EntityBankStatement.ID?>(
            get: { wrappedValue?.id },
            set: { id in
                wrappedValue = statements.first { $0.id == id }
            }
        )
    }
}

struct EditBankStatementView: View {
    @Binding var statement: EntityBankStatement?
    @State private var num: Int = 0
    @State private var startDate: Date = Date()
    @State private var startSolde: Double = 0.0
    // Ajoutez les autres propriétés nécessaires
    @Environment(\.dismiss) private var dismiss
    
    var isEditing: Bool
    
    var body: some View {
        Form {
            TextField("Num", value: $num, format: .number)
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            TextField("Solde Init", value: $startSolde, format: .currency(code: "EUR"))
            // Ajoutez les autres champs pour interDate, interSolde, etc.
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            if isEditing, let statement = statement {
                num = statement.num
                startDate = statement.startDate
                startSolde = statement.startSolde
                // Mettez à jour les autres champs
            }
        }
    }
    
    private func save() {
        
        @Environment(\.modelContext) var modelContext
        
        if isEditing, let statement = statement {
            statement.num = num
            statement.startDate = startDate
            statement.startSolde = startSolde
            // Mettez à jour les autres propriétés
        } else {
            let newStatement = EntityBankStatement(num: num, startDate: startDate, startSolde: startSolde)
            BankStatementManager.shared.configure(with: modelContext)
//            BankStatementManager.shared.create(account: account, num: num)
            modelContext.insert(newStatement)
        }
    }
}

struct DragPDFView: View {
    @Binding var pdfData: Data?
    
    var body: some View {
        Rectangle()
            .fill(Color.red)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                guard let provider = providers.first else { return false }
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                    if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        pdfData = try? Data(contentsOf: url)
                    }
                }
                return true
            }
            .overlay(Text("Drop a PDF here").foregroundColor(.white))
    }
}

struct PDFPreview: View {
    let pdfData: Data?
    
    var body: some View {
        if let data = pdfData, let pdfDocument = PDFDocument(data: data) {
            PDFKitRepresentedView(pdfDocument: pdfDocument)
        } else {
            Rectangle()
            //                .fill(Color.gray)
                .overlay(Text("No PDF"))
        }
    }
}

struct PDFKitRepresentedView: NSViewRepresentable {
    let pdfDocument: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = pdfDocument
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
}

