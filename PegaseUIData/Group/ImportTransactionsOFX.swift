//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 24/05/2025.
//


import SwiftUI
import UniformTypeIdentifiers
import Foundation
import SwiftData

func OFXImportTransactionView(from url: URL, into context: ModelContext) {
    guard let content = try? String(contentsOf: url, encoding: .isoLatin1) else { return }

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

        if let account = CurrentAccountManager.shared.getAccount() {
            let transaction = EntityTransactions()
            transaction.dateOperation = date.noon
            transaction.datePointage = date.noon

            
//                date: date, amount: amount, name: name, memo: memo, type: type)
            transaction.account = account
            context.insert(transaction)
        }
    }

    try? context.save()
}

extension DateFormatter {
    static let ofxDate: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
}
