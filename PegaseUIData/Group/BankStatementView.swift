////
////  BankStatementView.swift
////  PegaseUI
////
////  Created by Thierry hentic on 30/10/2024.
////
//
//import SwiftUI
//import SwiftData
//import PDFKit
//
//struct BankStatementView: View {
//    
//    @Binding var isVisible: Bool
//    
//    var body: some View {
//        BankStatementTableView()
//            .padding()
//            .task {
//                await performFalseTask()
//            }
//    }
//    private func performFalseTask() async {
//        // Exécuter une tâche asynchrone (par exemple, un délai)
//        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
//        isVisible = false
//    }
//}
//
//struct BankStatementTableView: View {
//    @Environment(\.modelContext) private var modelContext
//    
//    @State private var statements: [EntityBankStatement] = []
//    @State private var selectedStatement: EntityBankStatement? // Sélectionne l'entité complète
//    @State private var isEditing: Bool = false
//    @State private var showEditSheet: Bool = false
//    
//    var body: some View {
//        VStack(spacing: 10) {
//            Table(statements, selection: $selectedStatement.bindingId(from: statements)) {
//                TableColumn("Num") { statement in
//                    Text("\(statement.num)")
//                }
//                TableColumn("Start Date") { statement in
//                    Text(statement.startDate, style: .date)
//                }
//                TableColumn("Start Balance") { statement in
//                    Text("\(statement.startSolde, specifier: "%.2f") €")
//                }
//                TableColumn("Inter Date") { statement in
//                    Text(statement.interDate, style: .date)
//                }
//                TableColumn("Inter Balance") { statement in
//                    Text("\(statement.interSolde, specifier: "%.2f") €")
//                }
//                TableColumn("End Date") { statement in
//                    Text(statement.endDate, style: .date)
//                }
//                TableColumn("End Balance") { statement in
//                    Text("\(statement.endSolde, specifier: "%.2f") €")
//                }
//                TableColumn("CB Date") { statement in
//                    Text(statement.cbDate, style: .date)
//                }
//                TableColumn("CB Balance") { statement in
//                    Text("\(statement.cbSolde, specifier: "%.2f") €")
//                }
//                TableColumn("PDF") { statement in
//                    Text(statement.pdfLink)
//                }
//            }
//            .frame(height: 300)
//            HStack {
//                // Bouton pour ajouter un enregistrement
//                Button(action: {
//                    isEditing = false
//                    showEditSheet = true
//                }) {
//                    Label("Add", systemImage: "plus")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                
//                // Bouton pour modifier un enregistrement
//                Button(action: {
//                    isEditing = true
//                    showEditSheet = true
//                }) {
//                    Label("Edit", systemImage: "pencil")
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                
//                // Bouton pour supprimer un enregistrement
//                Button(action: {
//                    delete(selectedStatement!)
//                }) {
//                    Label("Delete", systemImage: "trash")
//                        .padding()
//                        .background(Color.red)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//            }
//            .contextMenu {
//                Button("Add") {
//                    isEditing = false
//                    showEditSheet = true
//                }
//                if let selected = selectedStatement {
//                    Button("Edit") {
//                        isEditing = true
//                        showEditSheet = true
//                    }
//                    Button("Delete") {
//                        delete(selected)
//                    }
//                }
//            }
//            .onAppear {
//                fetchData()
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Utilise tout l'espace parent et aligne en haut
//        
//        .sheet(isPresented: $showEditSheet) {
////            EditBankStatementView(statement: $selectedStatement, isEditing: isEditing)
//            EditBankStatementView( isEditing: isEditing)
//        }
//    }
//    
//    private func fetchData() {
//        guard let account = BankStatementManager.shared.currentAccount else { return }
//        statements = BankStatementManager.shared.getAllDatas(for: account)
//    }
//    
//    private func delete(_ statement: EntityBankStatement) {
//        BankStatementManager.shared.remove(entity: statement)
//        fetchData()
//    }
//}
//
//// MARK: - Extension pour Binding sur ID
//
//extension Binding where Value == EntityBankStatement? {
//    /// Permet de transformer un `Binding<EntityBankStatement?>` en un `Binding<ID?>` pour les Tables
//    func bindingId(from statements: [EntityBankStatement]) -> Binding<EntityBankStatement.ID?> {
//        Binding<EntityBankStatement.ID?>(
//            get: { wrappedValue?.id },
//            set: { id in
//                wrappedValue = statements.first { $0.id == id }
//            }
//        )
//    }
//}
//
//struct EditBankStatementView: View {
//    
//    var isEditing: Bool
//    var selectedStatement: EntityBankStatement? // Sélectionne l'entité complète
//
//    
//    @Environment(\.modelContext) var modelContext
//    @Environment(\.dismiss) var dismiss
//    
//    @State private var reference: String = "100"
//    @State private var startDate: Date = Date()
//    @State private var oldBalance: String = "0,00 €"
//    @State private var intermediateDate: Date = Date()
//    @State private var intermediateBalance: String = "0,00 €"
//    @State private var endDate: Date = Date()
//    @State private var newBalance: String = "0,00 €"
//    @State private var cbDate: Date = Date()
//    @State private var cbBalance: String = "0,00 €"
//    
//    @State private var pdfURL: URL?
//    @State private var pdfDocument: PDFDocument?
//    
//    var body: some View {
//        VStack {
//            Text("Bank Statement")
//                .font(.headline)
//            
//            HStack {
//                // Formulaire
//                VStack(alignment: .leading, spacing: 10) {
//                    LabeledTextField(label: "Reference", text: $reference)
//                    LabeledDatePicker(label: "Start date", date: $startDate)
//                    LabeledTextField(label: "Ancien solde", text: $oldBalance)
//                    LabeledDatePicker(label: "Date Intermediaire", date: $intermediateDate)
//                    LabeledTextField(label: "Solde intermediaire", text: $intermediateBalance)
//                    LabeledDatePicker(label: "End date", date: $endDate)
//                    LabeledTextField(label: "New balance", text: $newBalance)
//                    LabeledDatePicker(label: "Date CB", date: $cbDate)
//                    LabeledTextField(label: "Solde CB", text: $cbBalance)
//                    
//                    // Zone de drop PDF
//                    PDFDropView(pdfURL: $pdfURL, pdfDocument: $pdfDocument)
//                        .frame(height: 60)
//                        .padding(.top, 5)
//                }
//                .frame(width: 300)
//                
//                // Aperçu PDF
//                PDFPreview(pdfDocument: pdfDocument)
//                    .frame(width: 300, height: 300)
//                    .background(Color.gray.opacity(0.2))
//            }
//            .padding()
//            
//            // Boutons
//            HStack {
//                Button("Cancel") { dismiss() }
//                Spacer()
//                Button("OK") { dismiss() }
//                    .keyboardShortcut(.defaultAction)
//            }
//            .padding()
//        }
//        .frame(width: 650, height: 400)
//        .padding()
//    }
//}
//
////private func save() {
////    //        if isEditing, let statement = statement {
////    //            statement.num = num
////    //            statement.startDate = startDate
////    //            statement.startSolde = startSolde
////    //            // Mettez à jour les autres propriétés
////    //        } else {
////    //            let newStatement = EntityBankStatement(num: num, startDate: startDate, startSolde: startSolde)
////    //            modelContext.insert(newStatement)
////    //        }
////    //            }
////}
//
//// MARK: - Composants Réutilisables
//
//struct LabeledTextField: View {
//    let label: String
//    @Binding var text: String
//    
//    var body: some View {
//        HStack {
//            Text(label)
//                .frame(width: 130, alignment: .leading)
//            TextField("", text: $text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(width: 120)
//        }
//    }
//}
//
//struct LabeledDatePicker: View {
//    let label: String
//    @Binding var date: Date
//    
//    var body: some View {
//        HStack {
//            Text(label)
//                .frame(width: 130, alignment: .leading)
//            DatePicker("", selection: $date, displayedComponents: .date)
//                .labelsHidden()
//                .frame(width: 120)
//        }
//    }
//}
//
//
//struct PDFDropView: View {
//    @Binding var pdfURL: URL?
//    @Binding var pdfDocument: PDFDocument?
//
//    var body: some View {
//        RoundedRectangle(cornerRadius: 5)
//            .fill(Color.red)
//            .overlay(
//                Text("Drop PDF here")
//                    .foregroundColor(.white)
//                    .bold()
//            )
//            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
//                if let item = providers.first {
//                    item.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
//                        guard let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
//                        DispatchQueue.main.async {
//                            pdfURL = url
//                            pdfDocument = PDFDocument(url: url)
//                        }
//                    }
//                }
//                return true
//            }
//    }
//}
//
//struct PDFPreview: View {
//    let pdfDocument: PDFDocument?
//
//    var body: some View {
//        if let document = pdfDocument {
//            PDFKitView(document: document)
//        } else {
//            Color.gray.opacity(0.2)
//        }
//    }
//}
//
//struct PDFKitView: NSViewRepresentable {
//    let document: PDFDocument
//
//    func makeNSView(context: Context) -> PDFView {
//        let pdfView = PDFView()
//        pdfView.document = document
//        pdfView.autoScales = true
//        return pdfView
//    }
//
//    func updateNSView(_ nsView: PDFView, context: Context) {
//        nsView.document = document
//    }
//}
//
//
//
//private let dateFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    return formatter
//}()
//
//extension DateFormatter {
//    static let shortDate: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd/MM/yy"
//        return formatter
//    }()
//}
//
