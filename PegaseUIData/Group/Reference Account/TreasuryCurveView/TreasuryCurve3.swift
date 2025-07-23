//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts




protocol TReasuryManaging {
    func configure(with chartView: LineChartView)
    func updateAccount(minDate: Date) 

}

class TresuryLineViewModel: ObservableObject {
    
    @Published var listTransactions: [EntityTransaction] = []
    @Published var dataGraph: [DataTresorerie] = []
    @Published var dataEntries: [ChartDataEntry] = []

    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0

    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    @Published var lowerValue: Double = 0
    @Published var upperValue: Double = 30

    
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
        self.lowerValue = 0
        self.upperValue = Double(max(0, (allTransactions.last?.dateOperation.timeIntervalSince(allTransactions.first?.dateOperation ?? Date())) ?? 0) / 86400)

        guard !allTransactions.isEmpty else {
            self.dataGraph = []
            self.listTransactions = []
            return
        }
        
        firstDate = (allTransactions.first?.dateOperation.timeIntervalSince1970)! - hourSeconds
        lastDate = (allTransactions.last?.dateOperation.timeIntervalSince1970)! + hourSeconds
        let miniDate = allTransactions.first?.dateOperation
        
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
    
    func refresh(for account: EntityAccount?, minDate: Date)  {
        guard account != nil else {
            self.listTransactions = []
            self.dataGraph = []
            return
        }
        
        let allTransactions = ListTransactionsManager.shared.getAllData()

        self.listTransactions = allTransactions
        self.updateChartData()

        updateAccount(minDate: minDate)
        updateChartData()              // pour mettre à jour la courbe
    }
    
    func updateChartData() {
        var dataGraph: [DataTresorerie] = []

        guard !listTransactions.isEmpty else {
            DispatchQueue.main.async { self.dataGraph = dataGraph }
            return }
        
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: listTransactions, by: { calendar.startOfDay(for: $0.datePointage) })
        
        let startOffset = Int(lowerValue)
        let endOffset = Int(upperValue)
        
        let initAccount = InitAccountManager.shared.getAllData()
        var soldeRealise = initAccount?.realise ?? 0
        var soldePrevu = initAccount?.prevu ?? 0
        var soldeEngage = initAccount?.engage ?? 0
        
        for offset in startOffset...endOffset {
            let dayDate = Date(timeIntervalSince1970: firstDate + Double(offset) * hourSeconds)
            let dayTransactions = grouped[dayDate] ?? []
            
            var prevu = 0.0
            var engage = 0.0
            
            for tx in dayTransactions {
                switch tx.status?.type {
                case .planned: prevu += tx.amount
                case .inProgress: engage += tx.amount
                case .executed: soldeRealise += tx.amount
                case .none: break
                }
            }
            soldePrevu += soldeRealise + engage + prevu
            soldeEngage += soldeRealise + engage
            
            dataGraph.append(DataTresorerie(
                x: Double(offset),
                soldeRealise: soldeRealise,
                soldeEngage: soldeEngage,
                soldePrevu: soldePrevu
            ))
        }
        DispatchQueue.main.async { self.dataGraph = dataGraph }
    }
}
