//
//  EntityBankStatements.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 29/01/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers


final class StatementViewManager: ObservableObject {
    @Published var currentAccount: EntityAccount?
    @Published var statements: [EntityBankStatement]?
}

struct BankStatementView: View {

    @Binding var isVisible: Bool
    @StateObject private var currentAccountManager = CurrentAccountManager.shared
    @StateObject private var statementViewManager = StatementViewManager()

    var body: some View {
        BankStatementTableView()
            .environmentObject(statementViewManager)
            .environmentObject(currentAccountManager)
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
    @EnvironmentObject var statementViewManager: StatementViewManager
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    
    @Query private var statements: [EntityBankStatement]
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    
    @State private var selection: UUID?
    @State private var selectedStatement: EntityBankStatement?
    @State private var dragOver = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationSplitView {
            BankStatementTableView1(statements: statementViewManager.statements ?? [], selection: $selection)
//            Table(statementViewManager.statements ?? [], selection: $selection) {
//                TableColumn("N°") { statement in
//                    Text("\(statement.num)")
//                }
//                TableColumn("Date début") { statement in
//                    Text(dateFormatter.string(from: statement.startDate))
//                }
//                TableColumn("Solde initial") { statement in
//                    Text(String(format: "%.2f €", statement.startSolde))
//                }
//                TableColumn("Date inter.") { statement in
//                    Text(dateFormatter.string(from: statement.interDate))
//                }
//                TableColumn("Solde inter.") { statement in
//                    Text(String(format: "%.2f €", statement.interSolde))
//                }
//                TableColumn("Date fin") { statement in
//                    Text(dateFormatter.string(from: statement.endDate))
//                }
//                TableColumn("Solde final") { statement in
//                    Text(String(format: "%.2f €", statement.endSolde))
//                }
//                TableColumn("Date CB") { statement in
//                    Text(dateFormatter.string(from: statement.cbDate))
//                }
//                TableColumn("Solde CB") { statement in
//                    Text(String(format: "%.2f €", statement.cbSolde))
//                }
//                TableColumn( "Name") { statement in
//                    Text(statement.accountName)
//                }
//                TableColumn("Surname") { statement in
//                    Text(statement.accountSurname)
//                }
//
//            }
            .frame(height: 300)
            .onChange(of: selection) { oldValue, newValue in
                selectedStatement = nil // Désactive l’édition automatique
                
                if let selectedId = newValue,
                   let selected = statements.first(where: { $0.id == selectedId }) {
                    selectedStatement = selected
                }
            }
            .onAppear {
                if let account = currentAccountManager.currentAccount {
                    statementViewManager.currentAccount = account
                }
                
                // Créer un nouvel enregistrement si la base de données est vide
                if statementViewManager.statements == nil {
                    if let account = CurrentAccountManager.shared.getAccount() {
                        statementViewManager.currentAccount = account
                    } else {
                        print("Aucun compte disponible.")
                    }
                    BankStatementManager.shared.configure(with: modelContext)
                    let statements = BankStatementManager.shared.getAllDatas()
                    statementViewManager.statements = statements
                    
                    if statements == nil {
                        
                        let newStatements = EntityBankStatement()
                        statementViewManager.statements!.append( newStatements   )
                        modelContext.insert(newStatements)
                    }
                }
            }
            .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                
                if let account = newAccount {
                    statementViewManager.statements = nil
                    statementViewManager.currentAccount = account
                    
                    loadOrCreate(for: account)
                }
            }
            
            HStack {
                // Bouton pour ajouter un enregistrement
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Bouton pour modifier un enregistrement
                Button(action: {
                    showingEditSheet = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedStatement == nil) // Désactive le bouton si aucun élément n'est sélectionné
                
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
                .disabled(selectedStatement == nil) // Désactive le bouton si aucun élément n'est sélectionné
            }
            Spacer()
            
        } detail: {
            if let statement = selectedStatement {
                StatementDetailView(statement: statement)
            } else {
                Text("Select a statement")
            }
        }
        
        .sheet(isPresented: $showingEditSheet) {
            StatementFormView(statement: selectedStatement)
        }
        
        .sheet(isPresented: $showingAddSheet) {
            StatementFormView(statement: nil)
        }
    }
    
    private func loadOrCreate(for account: EntityAccount) {
        
        BankStatementManager.shared.configure(with: modelContext)
        if let existing = BankStatementManager.shared.getAllDatas() {
            statementViewManager.statements = existing
        } else {
            let entity = EntityBankStatement()
            entity.account = account
            modelContext.insert(entity)
            statementViewManager.statements!.append( entity)
        }
    }
    
    
    private func delete(_ statement: EntityBankStatement) {
        modelContext.delete(statement)
        if selection == statement.id {
            selection = nil
        }
        try? modelContext.save()
    }
}

struct BankStatementTableView1: View {
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var statements: [EntityBankStatement]
    @Binding var selection: UUID?

    var body: some View {
        Table(statements, selection: $selection) {
            
            Group {
                TableColumn("N°") {  (statement: EntityBankStatement) in Text("\(statement.num)") }
                TableColumn("Start Date") { statement in Text(dateFormatter.string(from: statement.startDate)) }
                TableColumn("Initial Balance") { statement in Text(statement.formattedStartSolde) }
                TableColumn("Date inter.") { statement in Text(dateFormatter.string(from: statement.interDate)) }
                TableColumn("Inter. Balance") { statement in Text(statement.formattedInterSolde) }
            }
            
            Group {
                TableColumn("End Date") {  (statement: EntityBankStatement) in Text(dateFormatter.string(from: statement.endDate)) }
                TableColumn("End Balance") { statement in Text(String(format: "%.2f €", statement.endSolde)) }
                TableColumn("Date CB") { statement in Text(dateFormatter.string(from: statement.cbDate)) }
                TableColumn("CB Balance") { statement in Text(String(format: "%.2f €", statement.cbSolde)) }
                TableColumn("Surname") { statement in Text(statement.accountSurname) }
                TableColumn("Name") { statement in Text(statement.accountName) }
            }
        }
    }
}

struct StatementFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let statement: EntityBankStatement?
    @State private var num: String = ""
    @State private var startDate = Date()
    @State private var startSolde: String = ""
    @State private var interDate = Date()
    @State private var interSolde: String = ""
    @State private var endDate = Date()
    @State private var endSolde: String = ""
    @State private var cbDate = Date()
    @State private var cbSolde: String = ""
    @State private var pdfData: Data?
    @State private var dragOver = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General information") {
                    TextField("Number", text: $num)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    TextField("Solde initial", text: $startSolde)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Date intermédiaire", selection: $interDate, displayedComponents: .date)
                    TextField("Solde intermédiaire", text: $interSolde)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    TextField("Solde final", text: $endSolde)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Date CB", selection: $cbDate, displayedComponents: .date)
                    TextField("Solde CB", text: $cbSolde)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Document PDF") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(dragOver ? Color.red.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(height: 100)
                        
                        Text(pdfData != nil ? "Selected PDF" : "Drop your PDF here")
                    }
                    .onDrop(of: [UTType.pdf], delegate: PDFDropDelegate(pdfData: $pdfData, isDragOver: $dragOver))
                }
            }
            .padding()
            .navigationTitle(statement == nil ? "Nouveau relevé" : "Modifier le relevé")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveStatement()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let statement = statement {
                num = String(statement.num)
                startDate = statement.startDate
                startSolde = String(format: "%.2f", statement.startSolde)
                interDate = statement.interDate
                interSolde = String(format: "%.2f", statement.interSolde)
                endDate = statement.endDate
                endSolde = String(format: "%.2f", statement.endSolde)
                cbDate = statement.cbDate
                cbSolde = String(format: "%.2f", statement.cbSolde)
                pdfData = statement.pdfDoc
            }
        }
    }
    
    private func saveStatement() {
        let newStatement: EntityBankStatement
        if let existingStatement = statement {
            newStatement = existingStatement
        } else {
            newStatement = EntityBankStatement()
            modelContext.insert(newStatement)
        }
        
        newStatement.num = Int(num) ?? 0
        newStatement.startDate = startDate
        newStatement.startSolde = Double(startSolde) ?? 0.0
        newStatement.interDate = interDate
        newStatement.interSolde = Double(interSolde) ?? 0.0
        newStatement.endDate = endDate
        newStatement.endSolde = Double(endSolde) ?? 0.0
        newStatement.cbDate = cbDate
        newStatement.cbSolde = Double(cbSolde) ?? 0.0
        newStatement.pdfDoc = pdfData
        
        try? modelContext.save()
    }
}

struct PDFDropDelegate: DropDelegate {
    @Binding var pdfData: Data?
    @Binding var isDragOver: Bool
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [UTType.pdf])
    }
    
    func dropEntered(info: DropInfo) {
        isDragOver = true
    }
    
    func dropExited(info: DropInfo) {
        isDragOver = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        isDragOver = false
        
        guard let provider = info.itemProviders(for: [UTType.pdf]).first else { return false }
        
       let _ = provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { (urlData, error) in
            if let url = urlData as? URL {
                do {
                    let data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        self.pdfData = data
                    }
                } catch {
                    print("Erreur lors du chargement du PDF: \(error)")
                }
            }
        }
        
        return true
    }
}

struct StatementDetailView: View {
    let statement: EntityBankStatement
    
    var body: some View {
        VStack {
            if let pdfData = statement.pdfDoc {
                PDFKitView(data: pdfData)
            } else {
                Text("Aucun PDF disponible")
            }
        }
        .padding()
    }
}

// PDFKit wrapper for SwiftUI
import PDFKit

struct PDFKitView: NSViewRepresentable {
    let data: Data
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}
