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



@MainActor
protocol TeeasuryManaging {
    func refresh(for account: EntityAccount?, minDate: Date)
    func updateChartData()
}

//class TresuryLineViewModel: ObservableObject, TeeasuryManaging {
//    @Published var listTransactions: [EntityTransaction] = []
//    @Published var dataGraph: [DataTresorerie] = []
//
//    private(set) var firstDate: Date = Date()
//    private(set) var lastDate: Date = Date()
//
//    @Published var lowerValue: Double = 0
//    @Published var upperValue: Double = 0
//
//    private let hourSeconds = 86400.0
//    private var groupedTransactions: [Date: [EntityTransaction]] = [:]
//
//    func refresh(for account: EntityAccount?, minDate: Date) {
//        guard let account else {
//            listTransactions = []
//            dataGraph = []
//            return
//        }
//
//        listTransactions = ListTransactionsManager.shared
//            .getAllData()
//            .filter { $0.account == account }
//            .sorted { $0.dateOperation < $1.dateOperation }
//
//        guard let first = listTransactions.first?.dateOperation,
//              let last = listTransactions.last?.dateOperation else { return }
//
//        firstDate = Calendar.current.startOfDay(for: first)
//        lastDate = Calendar.current.startOfDay(for: last)
//        lowerValue = 0
//        upperValue = lastDate.timeIntervalSince(firstDate) / hourSeconds
//
//        groupedTransactions = Dictionary(grouping: listTransactions) {
//            Calendar.current.startOfDay(for: $0.datePointage)
//        }
//
//        updateChartData()
//    }
//
//    func updateChartData() {
//        guard !listTransactions.isEmpty else { return }
//        var data: [DataTresorerie] = []
//        let start = Int(lowerValue)
//        let end = Int(upperValue)
//
//        var soldeRealise = InitAccountManager.shared.getAllData()?.realise ?? 0
//        var soldePrevu = InitAccountManager.shared.getAllData()?.prevu ?? 0
//        var soldeEngage = InitAccountManager.shared.getAllData()?.engage ?? 0
//
//        for offset in start...end {
//            let currentDate = firstDate.addingTimeInterval(Double(offset) * hourSeconds)
//            let dayTransactions = groupedTransactions[currentDate] ?? []
//
//            let prevu = dayTransactions.filter { $0.status?.type == .planned }.reduce(0) { $0 + $1.amount }
//            let engage = dayTransactions.filter { $0.status?.type == .inProgress }.reduce(0) { $0 + $1.amount }
//            let executed = dayTransactions.filter { $0.status?.type == .executed }.reduce(0) { $0 + $1.amount }
//
//            soldeRealise += executed
//            soldeEngage += engage
//            soldePrevu += prevu
//
//            data.append(DataTresorerie(
//                x: Double(offset),
//                soldeRealise: soldeRealise,
//                soldeEngage: soldeEngage,
//                soldePrevu: soldePrevu
//            ))
//        }
//        DispatchQueue.main.async { self.dataGraph = data }
//    }
//}

class TresuryLineViewModel: ObservableObject, TeeasuryManaging {
    
    @Published var listTransactions: [EntityTransaction] = []
    @Published var dataGraph: [DataTresorerie] = []
    @Published var dataEntries: [ChartDataEntry] = []

    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0

    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    @Published var lowerValue: Double = 0
    @Published var upperValue: Double = 0

    let hourSeconds = 3600.0 * 24.0 // one day
    
    static let shared = TresuryLineViewModel()

    
//    func updateAccount(minDate: Date) {
    
    @MainActor func refresh(for account: EntityAccount?, minDate: Date)  {
        guard account != nil else {
            self.listTransactions = []
            self.dataGraph = []
            return
        }
        
        let allTransactions = ListTransactionsManager.shared.getAllData()

        self.listTransactions = allTransactions
        self.updateChartData()
    }
    
    @MainActor func updateChartData() {
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
        DispatchQueue.main.async {
            self.dataGraph = dataGraph
        }
    }
}
