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
    
    // Récupérer les enregistrements via une requête SwiftData
    @Query var enregistrements: [EntityBankStatement]
    @Environment(\.modelContext) var modelContext
    
    @State private var selectedBankStatement = Set<EntityBankStatement.ID>()
    @State private var enregistrementAEditer: EntityBankStatement?
    @State private var isShowingDialog = true
    @State private var showingEditDialog = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        
        Table( enregistrements, selection: $selectedBankStatement)
        {
            TableColumn("Num") { enregistrement in
                Text("\(enregistrement.num)")
            }
            
            TableColumn("Start Date") { enregistrement in
                Text(DateFormatter.shortDate.string(from: enregistrement.startDate))
            }
            TableColumn("Start Balance") { enregistrement in
                Text("€\(enregistrement.startSolde, specifier: "%.2f")")
            }
            
            TableColumn("Inter Date") { enregistrement in
                Text(DateFormatter.shortDate.string(from: enregistrement.interDate))
            }
            TableColumn("Inter Balance") { enregistrement in
                Text("€\(enregistrement.interSolde, specifier: "%.2f")")
            }
            
            TableColumn("End Date") { enregistrement in
                Text(DateFormatter.shortDate.string(from: enregistrement.endDate))
            }
            TableColumn("End Balance") { enregistrement in
                Text("€\(enregistrement.endSolde, specifier: "%.2f")")
            }
            
            TableColumn("CB Date") { enregistrement in
                Text(DateFormatter.shortDate.string(from: enregistrement.cbDate))
            }
            TableColumn("CB Balance") { enregistrement in
                Text("\(enregistrement.cbSolde, specifier: "%.2f") €")
            }
            
            //            TableColumn("PDF") { enregistrement in
            //                if let pdfLink = enregistrement.pdfName {
            //                    Link("PDF", destination: pdfLink)
            //                } else {
            //                    Text("N/A")
            //                }
            //            }
            
            // Fonction helper pour déterminer la couleur de fond
//            func rowBackground(for index: Int) -> Color {
//                index.isMultiple(of: 2) ? Color(.systemGray6) : Color(.white)
//            }
//
        }
        
        .frame(minWidth: 800, minHeight: 400)
        .contextMenu {
            Button("Add") {
                //                addBankStatement()
            }
            Button("Édit") {
                //                showingEditDialog = true
                //                selectedBankStatement = item
            }
            Button("Delete") {
                //                showingDeleteAlert = true
                //                selectedBankStatement = item
            }
        }
        .alert("Delete recording?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteBankStatement()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingEditDialog) {
            let _ = $selectedBankStatement
            //                EditBankStatementView(bankStatement: statement)
        }
    }
}


//    private func addBankStatement() {
//        let newStatement = EntityBankStatement()
//        modelContext.insert(newStatement)
//    }
//
private func deleteBankStatement() {
//    let statement = $selectedBankStatement
    //            modelContext.delete(statement)
    
}
//}
//
struct EditBankStatementView: View {
    @Bindable var bankStatement: EntityBankStatement
    
    var body: some View {
        VStack {
            TextField("Number", value: $bankStatement.num, format: .number)
            DatePicker("Date Début", selection: $bankStatement.startDate)
            TextField("Ancien Solde", value: $bankStatement.startSolde, format: .currency(code: "EUR"))
            // Ajoutez des champs pour les autres propriétés
            
            DragPDFView(pdfData: $bankStatement.pdfDoc)
                .frame(width: 200, height: 200)
            Button("Save") {
                // Fermer la vue ou une autre action
            }
        }
        .padding()
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
                .fill(Color.gray)
                .overlay(Text("Aucun PDF"))
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

