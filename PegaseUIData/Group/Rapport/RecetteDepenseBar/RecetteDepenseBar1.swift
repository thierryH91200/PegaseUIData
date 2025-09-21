////
////  RecetteDepenseBar1.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
//
import SwiftUI
import SwiftData
import DGCharts
import Combine


class RecetteDepenseBarViewModel: ObservableObject {
    @Published var recetteArray: [DataGraph] = []
    @Published var depenseArray: [DataGraph] = []
    
    @Published var dataEntriesDepense: [BarChartDataEntry] = []
    @Published var dataEntriesRecette: [BarChartDataEntry] = []
    
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    @Published var selectedCategories: Set<String> = []
    
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30

    var chartView : BarChartView?

    var listTransactions: [EntityTransaction] = []
    
    var totalValue: Double {
        recetteArray.map { $0.value }.reduce(0, +)
    }

    var labels: [String] {
        recetteArray.map { $0.name }
    }

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func updateChartData( startDate: Date, endDate: Date) {
        
        listTransactions = ListTransactionsManager.shared.getAllData(from:startDate, to:endDate)

        // grouped and sum
        self.recetteArray.removeAll()
        self.depenseArray.removeAll()
        var dataArray = [DataGraph]()
        
        for listTransaction in listTransactions {
            
            let value = listTransaction.amount
            let id   = listTransaction.sectionIdentifier!
            
            let data  = DataGraph(name: id, value: value)
            dataArray.append(data)
        }
        
        let allKeys = Set<String>(dataArray.map { $0.name })
        for key in allKeys {
            var data = dataArray.filter({ $0.name == key && $0.value < 0 })
            var sum = data.map({ $0.value }).reduce(0, +)
            self.recetteArray.append(DataGraph(name: key, value: sum))
            
            data = dataArray.filter({ $0.name == key && $0.value >= 0 })
            sum = data.map({ $0.value }).reduce(0, +)
            self.depenseArray.append(DataGraph(name: key, value: sum))
        }
        
        self.depenseArray = depenseArray.sorted(by: { $0.name < $1.name })
        self.recetteArray = recetteArray.sorted(by: { $0.name < $1.name })
        
        let depenseEntries = depenseArray.enumerated().map { (idx, item) in
            BarChartDataEntry(x: Double(idx), y: item.value)
        }
        let recetteEntries = recetteArray.enumerated().map { (idx, item) in
            BarChartDataEntry(x: Double(idx), y: item.value)
        }
        DispatchQueue.main.async {
            self.dataEntriesDepense = depenseEntries
            self.dataEntriesRecette = recetteEntries
        }
    }
}
