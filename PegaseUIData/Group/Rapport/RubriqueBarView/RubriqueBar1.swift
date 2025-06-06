//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


class RubriqueBarViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataArray: [DataGraph] = []
    
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var nameRubrique: String = ""
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
    var totalValue: Double {
        resultArray.map { $0.value }.reduce(0, +)
    }
    
    var labels: [String] {
        resultArray.map { $0.name }
    }
    
    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
        
        dataArray.removeAll()
        guard nameRubrique != "" else { return }
        
        
        guard let currentAccount else { return }
        self.currencyCode = currentAccount.currencyCode

        let sort = [SortDescriptor(\EntityTransaction.dateOperation, order: .reverse)]
        let lhs = currentAccount.uuid

        let descriptor = FetchDescriptor<EntityTransaction>(
            predicate: #Predicate { transaction in
                transaction.account.uuid == lhs &&
                transaction.dateOperation >= startDate &&
                transaction.dateOperation <= endDate
            },
            sortBy: sort
        )
        var listTransactions: [EntityTransaction] = []

        do {
            listTransactions = try modelContext.fetch(descriptor)
        } catch {
            printTag("Error fetching data from CoreData")
        }
        
//        delegate?.updateListeTransactions( listTransactions)
        
        // grouped by month/year
        var name = ""
        var value = 0.0
        var color = NSColor.blue
        var section = ""
        resultArray.removeAll()
        dataArray.removeAll()

        for listTransaction in listTransactions {
            
            section = listTransaction.sectionIdentifier!
            let sousOperations = listTransaction.sousOperations
            value = 0.0
            for sousOperation in sousOperations where (sousOperation.category?.rubric!.name)! == nameRubrique {
                name  = (sousOperation.category?.rubric!.name)!
                value += sousOperation.amount
                color = (sousOperation.category?.rubric!.color)!
            }
            self.dataArray.append( DataGraph(section: section, name: name, value: value, color: color))
        }
        self.dataArray = self.dataArray.sorted(by: { $0.name < $1.name })
        self.dataArray = self.dataArray.sorted(by: { $0.section < $1.section })
        
        let allKeys = Set<String>(dataArray.map { $0.section })
        let strAllKeys = allKeys.sorted()
        
        for key in strAllKeys {
            let data = dataArray.filter({ $0.section == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            self.resultArray.append(DataGraph(section: key, name: key, value: sum, color: color))
        }
        dataArray = resultArray
    }
}
