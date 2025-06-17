//
//  EntityBankStatements.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 29/01/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit



final class StatementDataManager: ObservableObject {
    @Published var statements: [EntityBankStatement]? {
        didSet {
            // Sauvegarder les modifications dès qu'il y a un changement
            saveChanges()
        }
    }
    
    private var modelContext: ModelContext?
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    func saveChanges() {
        
        do {
            try modelContext?.save()
        } catch {
            printTag("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}

struct BankStatementView: View {
    
    @Binding var isVisible: Bool
    @StateObject private var dataManager = StatementDataManager()

    var body: some View {
        BankStatementListView()
            .environmentObject(dataManager)

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

struct BankStatementListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject var dataManager: StatementDataManager
        
    @State private var isAddDialogPresented = false
    @State private var isEditDialogPresented = false
    
    @State private var selectedItem: EntityBankStatement.ID?
    @State private var selectedStatement : EntityBankStatement?
    
    @State private var dragOver = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationSplitView {
            if let account = CurrentAccountManager.shared.getAccount() {
                Text("Account: \(account.name)")
                    .font(.headline)
            }
            
            BankStatementTable(statements: dataManager.statements ?? [], selection: $selectedItem)
                .frame(height: 300)
                .onAppear {
                    
                    // Créer un nouvel enregistrement si la base de données est vide
                    if dataManager.statements == nil {

                        DataContext.shared.context = modelContext
                        let statements = BankStatementManager.shared.getAllData()
                        dataManager.statements = statements
                    }
                }
            
                .onChange(of: selectedItem) { oldValue, newValue in
                    if let selected = newValue {
                        selectedItem = selected
                        selectedStatement =  dataManager.statements!.first(where: { $0.id == selected })

                    } else {
                        selectedStatement = nil // Désactive l’édition automatique
                        selectedItem = nil
                        
                        printTag("Aucun élément sélectionné dans CheckView/onChange")
                    }
                }
            
                .onChange(of: currentAccountManager.currentAccount) { old, newAccount in
                    
                    if newAccount != nil {
                        dataManager.statements = nil
                        selectedStatement = nil
                        selectedItem = nil
                        refreshData()
                    }
                }
            
            HStack {
                // Bouton pour ajouter un enregistrement
                Button(action: {
                    isAddDialogPresented = true
                }) {
                    Label("Add", systemImage: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Bouton pour modifier un enregistrement
                Button(action: {
                    isEditDialogPresented = true
                }) {
                    Label("Edit", systemImage: "pencil")
                        .padding()
                        .background(selectedStatement == nil ? Color.gray : Color.green) // Fond gris si désactivé
                        .opacity(selectedStatement == nil ? 0.6 : 1) // Opacité réduite si désactivé
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedStatement == nil) // Désactive le bouton si aucun élément n'est sélectionné
                
                // Bouton pour supprimer un enregistrement
                Button(action: {
                    delete()
                }) {
                    Label("Delete", systemImage: "trash")
                        .padding()
                        .background(selectedStatement == nil ? Color.gray : Color.red) // Fond gris si désactivé
                        .opacity(selectedStatement == nil ? 0.6 : 1) // Opacité réduite si désactivé
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
        
        .sheet(isPresented: $isEditDialogPresented) {
            StatementFormView(statement: selectedStatement)
        }
        
        .sheet(isPresented: $isAddDialogPresented) {
            StatementFormView(statement: nil)
        }
    }
        
    private func delete() {
        if let modeToDelete = selectedStatement {
            modelContext.delete(modeToDelete)  // Suppression de l'élément du contexte
            selectedStatement = nil  // Réinitialisation de la sélection
            selectedItem = nil
            try? modelContext.save()  // Sauvegarde du contexte après suppression
            refreshData()
        }
    }
    
    private func refreshData() {
        dataManager.statements = BankStatementManager.shared.getAllData()
    }
}

struct BankStatementTable: View {
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    var statements: [EntityBankStatement]
    @Binding var selection: EntityBankStatement.ID?
    
    var body: some View {
        Table(statements, selection: $selection) {
            
            Group {
                TableColumn("N°") {  (statement: EntityBankStatement) in Text("\(statement.num)") }
                TableColumn("Start Date") { statement in Text(dateFormatter.string(from: statement.startDate)) }
                TableColumn("Initial balance") { statement in Text(statement.formattedStartSolde) }
                TableColumn("Inter Date") { statement in Text(dateFormatter.string(from: statement.interDate)) }
                TableColumn("Inter balance") { statement in Text(statement.formattedInterSolde) }
            }
            
            Group {
                TableColumn("End Date") {  (statement: EntityBankStatement) in Text(dateFormatter.string(from: statement.endDate)) }
                TableColumn("End balance") { statement in Text(String(format: "%.2f €", statement.endSolde)) }
                TableColumn("Date CB") { statement in Text(dateFormatter.string(from: statement.cbDate)) }
                TableColumn("CB Balance") { statement in Text(String(format: "%.2f €", statement.cbSolde)) }
                TableColumn("Surname") { statement in Text(statement.accountSurname) }
                TableColumn("Name") { statement in Text(statement.accountName) }
            }
        }
    }
}

class StatementFormViewModel: ObservableObject {
    @Published var num: String = ""
    @Published var startDate = Date()
    @Published var startSolde: String = ""
    @Published var interDate = Date()
    @Published var interSolde: String = ""
    @Published var endDate = Date()
    @Published var endSolde: String = ""
    @Published var cbDate = Date()
    @Published var cbSolde: String = ""
    @Published var pdfData: Data?

    func load(from statement: EntityBankStatement) {
        num = String(statement.num)
        startDate = statement.startDate
        startSolde = formatPrice( statement.startSolde)
        interDate = statement.interDate
        interSolde = formatPrice( statement.interSolde)
        endDate = statement.endDate
        endSolde = formatPrice( statement.endSolde)
        cbDate = statement.cbDate
        cbSolde = formatPrice(statement.cbSolde)
        pdfData = statement.pdfDoc
    }

    func apply(to statement: EntityBankStatement) {
        statement.num = Int(num) ?? 0
        statement.startDate = startDate
        statement.startSolde = cleanDouble(from: startSolde)
        statement.interDate = interDate
        statement.interSolde = cleanDouble(from: interSolde)
        statement.endDate = endDate
        statement.endSolde = cleanDouble(from: endSolde)
        statement.cbDate = cbDate
        statement.cbSolde = cleanDouble(from: cbSolde)
        statement.pdfDoc = pdfData
    }

    func reset() {
        num = ""
        startDate = Date()
        startSolde = ""
        interDate = Date()
        interSolde = ""
        endDate = Date()
        endSolde = ""
        cbDate = Date()
        cbSolde = ""
        pdfData = nil
    }
}

struct StatementFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = StatementFormViewModel()
    
    let statement: EntityBankStatement?
    @State private var dragOver = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General information") {
                    TextField("Number", text: $viewModel.num)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    TextField("Initial balance", text: $viewModel.startSolde)                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Inter Date", selection: $viewModel.interDate, displayedComponents: .date)
                    TextField("Inter balance", text: $viewModel.interSolde)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                    TextField("Final balance", text: $viewModel.endSolde)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("CB Date", selection: $viewModel.cbDate, displayedComponents: .date)
                    TextField("CB Balance", text: $viewModel.cbSolde)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Document PDF") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(dragOver ? Color.red.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(height: 100)
                        
                        Text(viewModel.pdfData != nil ? "Selected PDF" : "Drop your PDF here")
                    }
                    .onDrop(of: [UTType.pdf], delegate: PDFDropDelegate(pdfData: $viewModel.pdfData, isDragOver: $dragOver))
                }
            }
            .padding()
            .navigationTitle(statement == nil ? "New statement" : "Edit statement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: statement) { _, newValue in
            if let statement = newValue {
                viewModel.load(from: statement)
            }
        }
        .onAppear {
            if let statement = statement {
                viewModel.load(from: statement)
            }
        }
    }
    
    private func save() {
        let entityBankStatement: EntityBankStatement
        
        if let existingStatement = statement {
            entityBankStatement = existingStatement
        } else {
            entityBankStatement = EntityBankStatement()
            modelContext.insert(entityBankStatement)
        }
        
        viewModel.apply(to: entityBankStatement)
        entityBankStatement.account = CurrentAccountManager.shared.getAccount()!
        
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
                    printTag("Erreur lors du chargement du PDF: \(error)")
                }
            }
        }
        
        return true
    }
}

func printTag( _ message: String, flag : Bool = true) {
    if flag == true {
        let tag = "[PegaseUIData]"
        print("\(tag) \(message)")
    }
}

struct StatementDetailView: View {
    let statement: EntityBankStatement
    
    var body: some View {
        VStack {
            if let pdfData = statement.pdfDoc {
                PDFKitView(data: pdfData)
            } else {
                Text("No PDF available")
            }
        }
        .padding()
    }
}

// PDFKit wrapper for SwiftUI

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
