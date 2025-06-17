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

        let firstOpDate = Calendar.current.startOfDay(for: allTransactions.first!.dateOperation)
        let lastOpDate = Calendar.current.startOfDay(for: allTransactions.last!.dateOperation)

        self.firstDate = firstOpDate.timeIntervalSince1970
        self.lastDate = lastOpDate.timeIntervalSince1970

        // Appliquer la plage sélectionnée
        let startDate = Calendar.current.date(byAdding: .day, value: Int(self.selectedStart), to: minDate)!
        let endDate   = Calendar.current.date(byAdding: .day, value: Int(self.selectedEnd), to: minDate)!

        let filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }

        DispatchQueue.main.async {
            self.listTransactions = filteredTransactions
        }
    }
}
