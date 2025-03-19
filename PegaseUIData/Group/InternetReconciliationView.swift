//
//  InternetReconciliationView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation
import SwiftData

struct InternetReconciliationView: View {
    
    @Binding var isVisible: Bool

    var body: some View {
        CSVImportView()
            .font(.title)
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

func readCSV(from url: URL) -> [[String]]? {
    
    guard url.startAccessingSecurityScopedResource() else {
        print("⚠️ Impossible d'accéder au fichier (Security Scoped)")
        return nil
    }
    
    defer { url.stopAccessingSecurityScopedResource() } // Libérer l'accès à la fin

    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        // Détecter le séparateur
        let separator: Character = content.contains(";") ? ";" : ","
        
        let parsedData = rows.map { $0.components(separatedBy: String(separator)) }
        return parsedData
    } catch {
        print("Erreur lors de la lecture du fichier CSV : \(error.localizedDescription)")
        return nil
    }
}

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showFileImporter = false
    @State private var csvData: [[String]] = []
    @State private var columnMapping: [String: Int] = [:] // Associe les attributs aux colonnes

    // Attributs disponibles
    let transactionAttributes = ["datePointage", "dateOperation", "libelle", "category", "paymentMode", "amount"]
    
    var body: some View {
        VStack {
            Button("Importer un fichier CSV") {
                showFileImporter = true
            }
            .frame(width: 200, height: 30, alignment: .center)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first, let data = readCSV(from: url) {
                        csvData = data
                    }
                case .failure(let error):
                    print("Erreur de sélection de fichier : \(error.localizedDescription)")
                }
            }
            
            if !csvData.isEmpty {
                Text("Aperçu du CSV").font(.headline)
                ScrollView(.horizontal) {
                    TableView(data: csvData)
                }
                
                Text("Associez les colonnes :").font(.headline)
                ForEach(transactionAttributes, id: \.self) { attribute in
                    Picker(attribute, selection: Binding(
                        get: { columnMapping[attribute] ?? -1 },
                        set: { columnMapping[attribute] = $0 }
                    )) {
                        Text("Ignorer").tag(-1)
                        ForEach(0..<(csvData.first?.count ?? 0), id: \.self) { index in
                            Text("Colonne \(index)").tag(index)
                        }
                    }
                    .frame(width: 300) // Réduit la largeur du picker
                    .pickerStyle(MenuPickerStyle()) // Utilisation d'un menu déroulant compact

                }
                
                Button("Importer") {
                    importCSVTransactions(context: modelContext)
                }
                .disabled(columnMapping.isEmpty)
            }
        }
        .padding()
    }
    
    // Fonction d'importation
    func importCSVTransactions(context: ModelContext) {
        guard !csvData.isEmpty else { return }
        
        let account = CurrentAccountManager.shared.getAccount()!
        PreferenceManager.shared.configure(with: context)
        PaymentModeManager.shared.configure(with: context)
        StatusManager.shared.configure(with: context)
        CategoriesManager.shared.configure(with: context)
        let entityPreference = PreferenceManager.shared.getAllDatas(for: account)

        for row in csvData.dropFirst() { // Ignorer l'en-tête
            
            let dateOperation = getDate(from: row, index: columnMapping["dateOperation"])
            let datePointage =  getDate(from: row, index: columnMapping["datePointage"])
            
            let paymentMode = getString(from: row, index: columnMapping["paymentMode"])
            let entityModePaiement = PaymentModeManager.shared.find(account: account, name: paymentMode) ?? (entityPreference!.paymentMode)!

            let status = getString(from: row, index: columnMapping["status"])
            let entityStatus = StatusManager.shared.find(name: status) ?? (entityPreference?.status)!
            
           let bankStatement = 0.0

            let libelle = getString(from: row, index: columnMapping["libelle"])
            let amount = getDouble(from: row, index: columnMapping["amount"])
            let category = getString(from: row, index: columnMapping["category"])
            let entityCategory = CategoriesManager.shared.find(account: account, name: category) ?? (entityPreference!.category)!
        
            let transaction = EntityTransactions()
            
            transaction.createAt  = Date()
            transaction.updatedAt = Date()

            transaction.dateOperation = dateOperation
            transaction.datePointage  = datePointage
            transaction.paymentMode   = entityModePaiement
            transaction.status        = entityStatus
            transaction.bankStatement = bankStatement
            transaction.checkNumber   = ""
            transaction.account       = account
            
            let sousTransaction = EntitySousOperations()
            sousTransaction.libelle  = libelle
            sousTransaction.amount  = amount
            sousTransaction.category = entityCategory
            sousTransaction.transaction = transaction
            
            context.insert(sousTransaction)

            transaction.addSubOperation(sousTransaction)


            context.insert(transaction)
        }
        
        do {
            try context.save()
            print("Importation réussie 🎉")
        } catch {
            print("Erreur lors de l'enregistrement : \(error)")
        }
    }
    
    // Fonctions utilitaires
    func getString(from row: [String], index: Int?) -> String {
        guard let index = index, index >= 0, index < row.count else { return "" }
        return row[index]
    }

    func getDouble(from row: [String], index: Int?) -> Double {
        guard let index = index, index >= 0, index < row.count else { return 0.0 }
        return Double(row[index]) ?? 0.0
    }

    func getDate(from row: [String], index: Int?) -> Date? {
        guard let index = index, index >= 0, index < row.count else { return Date().noon }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Ajuste selon le format de ton CSV
        return formatter.date(from: row[index])
    }
}

struct TableView: View {
    let data: [[String]]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<min(5, data.count), id: \.self) { rowIndex in
                HStack {
                    ForEach(data[rowIndex], id: \.self) { cell in
                        Text(cell)
                            .frame(width: 150, height: 30)
                            .border(Color.gray)
                    }
                }
            }
        }
    }
}
