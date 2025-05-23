//
//  ImportTransactions.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 19/03/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation
import SwiftData


struct ImportTransactionFileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showFileImporter = false
    @State private var showOFXImporter = false
    @State private var csvData: [[String]] = []
    @State private var columnMapping: [String: Int] = [:] // Associe les attributs aux colonnes

    // Attributs disponibles
    let transactionAttributes = ["datePointage", "dateOperation", "libelle", "category", "paymentMode", "amount"]
    
    var body: some View {
        VStack {
            Button("Import a CSV file") {
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
            
            Button("Import an OFX file") {
                showOFXImporter = true
            }
            .frame(width: 200, height: 30, alignment: .center)
            .fileImporter(
                isPresented: $showOFXImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importOFXTransactions(from: url, context: modelContext)
                        dismiss()
                    }
                case .failure(let error):
                    print("Erreur de sélection de fichier OFX : \(error.localizedDescription)")
                }
            }
            
            if !csvData.isEmpty {
                Text("CSV Preview").font(.headline)
                ScrollView(.horizontal) {
                    TableView(data: csvData)
                }
                
                Text("Match the columns :").font(.headline)
                ForEach(transactionAttributes, id: \.self) { attribute in
                    Picker(attribute, selection: Binding(
                        get: { columnMapping[attribute] ?? -1 },
                        set: { columnMapping[attribute] = $0 }
                    )) {
                        let csvData1 = csvData.dropFirst()
                        Text("Ignore").tag(-1)
                        ForEach(0..<(csvData1.first?.count ?? 0), id: \.self) { index in
                            Text("Colunn \(index)").tag(index)
                        }
                    }
                    .frame(width: 300) // Réduit la largeur du picker
                    .pickerStyle(MenuPickerStyle()) // Utilisation d'un menu déroulant compact

                }
                
                Button("Import") {
                    importCSVTransactions(context: modelContext)
                    dismiss()
                }
                .disabled(columnMapping.isEmpty)
            }
        }
        .padding()
    }
    
    // Fonction d'importation
    func importCSVTransactions(context: ModelContext) {
        guard !csvData.isEmpty else { return }
        
        let count = csvData.count
        print("Importation de \(count) transactions CSV.")
        
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
            let entityModePaiement = PaymentModeManager.shared.find(account: account, name: paymentMode) ?? entityPreference?.paymentMode

            let status = getString(from: row, index: columnMapping["status"])
            let entityStatus = StatusManager.shared.find(name: status) ?? entityPreference?.status
            
           let bankStatement = 0.0

            let libelle = getString(from: row, index: columnMapping["libelle"])
            let amount = getDouble(from: row, index: columnMapping["amount"])
            let category = getString(from: row, index: columnMapping["category"])
            let entityCategory = CategoriesManager.shared.find(account: account, name: category) ?? entityPreference?.category
        
            let transaction = EntityTransactions()
            
            transaction.createAt  = Date().noon
            transaction.updatedAt = Date().noon

            transaction.dateOperation = dateOperation!.noon
            transaction.datePointage  = datePointage!.noon
            transaction.paymentMode   = entityModePaiement
            transaction.status        = entityStatus
            transaction.bankStatement = bankStatement
            transaction.checkNumber   = "0"
            transaction.account       = account
            
            let sousTransaction = EntitySousOperations()
            sousTransaction.libelle  = libelle
            sousTransaction.amount  = amount
            sousTransaction.category = entityCategory
            sousTransaction.transaction = transaction
            
            context.insert(sousTransaction)
//            transaction.updateAmount()
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
        let value = row[index].replacingOccurrences(of: String(","), with: ".")
        return Double(value) ?? 0.0
    }

    func getDate(from row: [String], index: Int?) -> Date? {
        guard let index = index, index >= 0, index < row.count else { return Date().noon }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // Ajuste selon le format de ton CSV
        return formatter.date(from: row[index])?.noon
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

func importOFXTransactions(from url: URL, context: ModelContext) {
    guard url.startAccessingSecurityScopedResource() else {
        print("⚠️ Impossible d'accéder au fichier OFX (Security Scoped)")
        return
    }
    defer { url.stopAccessingSecurityScopedResource() }

    let encodings: [String.Encoding] = [.utf8, .windowsCP1252, .isoLatin1, .macOSRoman]

    var content: String? = nil
    for encoding in encodings {
        if let result = try? String(contentsOf: url, encoding: encoding), !result.isEmpty {
            content = result
            break
        }
    }
    guard let content = content else {
        print("⚠️ Impossible de lire le contenu du fichier OFX avec les encodages connus.")
        return
    }

    let blocks = content.components(separatedBy: "<STMTTRN>").dropFirst()
    for block in blocks {
        guard let end = block.range(of: "</STMTTRN>") else { continue }
        let transaction = String(block[..<end.lowerBound])

        func extract(_ tag: String) -> String {
            guard let range = transaction.range(of: "<\(tag)>") else { return "" }
            let after = transaction[range.upperBound...]
            return after.prefix(while: { $0 != "\n" && $0 != "\r" }).trimmingCharacters(in: .whitespaces)
        }

        let type = extract("TRNTYPE")
        let name = extract("NAME")
        let memo = extract("MEMO")
        let amountString = extract("TRNAMT").replacingOccurrences(of: "+", with: "")
        let amount = Double(amountString) ?? 0.0
        let dateString = extract("DTPOSTED").prefix(8)
        let date = DateFormatter.ofxDate.date(from: String(dateString)) ?? Date()

        let account = CurrentAccountManager.shared.getAccount()!

        let entityTransaction = EntityTransactions()
        entityTransaction.dateOperation = date.noon
        entityTransaction.datePointage = date.noon
        entityTransaction.account = account
        entityTransaction.checkNumber = "0"
        entityTransaction.bankStatement = 0.0

        let preference = PreferenceManager.shared.getAllDatas(for: account)
        entityTransaction.status = preference?.status
        entityTransaction.paymentMode = preference?.paymentMode

        let sousOperation = EntitySousOperations()
        sousOperation.amount = amount
        sousOperation.libelle = name
        sousOperation.category = preference?.category
        sousOperation.transaction = entityTransaction

        context.insert(sousOperation)
        entityTransaction.addSubOperation(sousOperation)
        context.insert(entityTransaction)
    }

    try? context.save()
}

//extension DateFormatter {
//    static let ofxDate: DateFormatter = {
//        let df = DateFormatter()
//        df.dateFormat = "yyyyMMdd"
//        df.timeZone = TimeZone(secondsFromGMT: 0)
//        return df
//    }()
//}
