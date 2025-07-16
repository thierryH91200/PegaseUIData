//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


class TresuryLineViewModel: ObservableObject {
    
    @Published var listTransactions: [EntityTransaction] = []
    @Published var dataGraph: [DataTresorerie] = []
    @Published var dataEntries: [ChartDataEntry] = []

    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0

    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    let hourSeconds = 3600.0 * 24.0 // one day

    
    @State private var chartView : LineChartView?
    
    static let shared = TresuryLineViewModel()

    func configure(with chartView: LineChartView)
    {
        self.chartView = chartView
    }
    
    func updateAccount(minDate: Date) {
        // Charger toutes les transactions d'abord
        let allTransactions = ListTransactionsManager.shared.getAllData()

        guard !allTransactions.isEmpty else {
            DispatchQueue.main.async {
                self.listTransactions = []
            }
            return
        }
        
        firstDate = (allTransactions.first?.dateOperation.timeIntervalSince1970)! - hourSeconds
        lastDate = (allTransactions.last?.dateOperation.timeIntervalSince1970)! + hourSeconds
        let miniDate = allTransactions.first?.dateOperation
        
        let totalDays = (lastDate - firstDate) / hourSeconds
//        minValue = 0
//        maxValue = totalDays
//        lowerValue = 0
//        upperValue = totalDays
        
//        printTag("\(firstDate)   \(lastDate)   \((lastDate - firstDate) / hourSeconds)")

        // Appliquer la plage sélectionnée
        let startDate = Calendar.current.date(byAdding: .day, value: Int(self.selectedStart), to: miniDate!)!
        let endDate   = Calendar.current.date(byAdding: .day, value: Int(self.selectedEnd), to: miniDate!)!

        let filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }

        DispatchQueue.main.async {
            self.listTransactions = filteredTransactions
        }
    }
}
