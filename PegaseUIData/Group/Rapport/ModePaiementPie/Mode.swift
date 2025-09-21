//
//  Untitled.swift
//  PegaseUIData
//
//  Created by thierryH24 on 21/09/2025.
//


//

class ModePaymentPieViewModel: ObservableObject {
    @Published var recetteArray: [DataGraph] = []
    @Published var depenseArray: [DataGraph] = []

    @Published var dataEntriesDepense: [PieChartDataEntry] = []
    @Published var dataEntriesRecette: [PieChartDataEntry] = []
    
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    var listTransactions: [EntityTransaction] = []

    var labelsExpense: [String] {
        depenseArray.map { $0.name }
    }
    var labelsIncome: [String] {
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

        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome = [DataGraph]()

        for listTransaction in listTransactions {

            let amount = listTransaction.amount
            let name = listTransaction.paymentMode?.name ?? "Inconnu"
            let color = listTransaction.paymentMode?.color ?? .gray

            if amount < 0 {
                let data = DataGraph(name: name, value: abs(amount), color: color)
                dataArrayExpense.append(data)
            } else {
                let data = DataGraph(name: name, value: amount, color: color)
                dataArrayIncome.append(data)
            }
        }

        self.depenseArray = summarizeData(from: dataArrayExpense, maxCategories: 6)
        self.recetteArray = summarizeData(from: dataArrayIncome, maxCategories: 6)

        print("[Pie] depenseArray: \(depenseArray.count), recetteArray: \(recetteArray.count)")
        
        self.dataEntriesDepense = pieChartEntries(from: depenseArray)
        self.dataEntriesRecette = pieChartEntries(from: recetteArray)
        print("[Pie] dataEntriesDepense: \(dataEntriesDepense.count), dataEntriesRecette: \(dataEntriesRecette.count)")
        for data in dataEntriesDepense {
            print("[Pie] dataEntriesDepense: \(data)")
        }
        
        // Do any additional setup after loading the view.
//       let ys1 = Array(1..<10).map { x in return sin(Double(x) / 2.0 / 3.141 * 1.5) * 100.0 }
//        let yse1 = ys1.enumerated().map { x, y in return PieChartDataEntry(value: y, label: String(x)) }
//
//        let data = PieChartData()
//        let ds1 = PieChartDataSet(entries: yse1, label: "Hello")
//
//        ds1.colors = ChartColorTemplates.vordiplom()
//
//        data.append(ds1)

    }
    
    private func summarizeData(from array: [DataGraph], maxCategories: Int = 6) -> [DataGraph] {
        let grouped = Dictionary(grouping: array, by: { $0.name })
        
        let summarized = grouped.map { (key, values) in
            let total = values.map { $0.value }.reduce(0, +)
            return DataGraph(name: key, value: total, color: values.first?.color ?? .gray)
        }

        // Trier du plus grand au plus petit
        let sorted = summarized.sorted { abs($0.value) > abs($1.value) }

        if sorted.count <= maxCategories {
            return sorted
        }

        let main = sorted.prefix(maxCategories)
        let other = sorted.dropFirst(maxCategories)

        let totalOthers = other.map { $0.value }.reduce(0, +)
        let othersData = DataGraph(name: "Autres", value: totalOthers, color: .gray)

        return Array(main) + [othersData]
    }
    
    private func pieChartEntries(from array: [DataGraph]) -> [PieChartDataEntry] {
        array.map {
            PieChartDataEntry(value: abs($0.value), label: $0.name, data: $0)
        }
    }
}

////
////  ModePaiementPie3.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
//
//
//  ModePaiementPie3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

//
//  SinglePieChartView.swift
//  PegaseUIData
//
//  Created by thierryH24 on 29/07/2025.
//

