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
    
    @Published var listTransactions: [EntityTransactions] = []
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
    
    func updateAccount() {
        let startDate: Date? = nil
        let endDate: Date? = nil
        let transactions = ListTransactionsManager.shared.getAllDatas(from: startDate, to: endDate)

        DispatchQueue.main.async {
            self.listTransactions = transactions
            if let first = transactions.first?.dateOperation.timeIntervalSince1970,
               let last = transactions.last?.dateOperation.timeIntervalSince1970 {
                self.firstDate = first
                self.lastDate = last
            }
        }
    }
}


