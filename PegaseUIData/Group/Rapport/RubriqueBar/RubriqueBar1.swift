//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

class RubriqueBarViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataArray: [DataGraph] = []
    
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var nameRubrique: String = ""
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []

    var listTransactions: [EntityTransaction] = []
    
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30

    
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
    
    func updateChartData( startDate: Date, endDate: Date) {
        
        dataArray.removeAll()
        guard nameRubrique != "" else { return }
        
        
        listTransactions = ListTransactionsManager.shared.getAllData(from:startDate, to:endDate)

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
