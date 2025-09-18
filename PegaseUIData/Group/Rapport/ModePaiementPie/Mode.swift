//
//  Mode.swift
//  PegaseUIData
//
//  Created by thierryH24 on 18/09/2025.
//

//
//  ModePaiementPie1.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

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

    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {

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

        listTransactions.removeAll()
        do {
            listTransactions = try modelContext.fetch(descriptor)
        } catch {
            printTag("Error fetching data from CoreData")
        }

        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome = [DataGraph]()

        for listTransaction in listTransactions {

            let amount = listTransaction.amount
            let nameModePaiement   = listTransaction.paymentMode?.name
            let color = listTransaction.paymentMode?.color
            
            if amount < 0 {
                let data  = DataGraph(name : nameModePaiement!, value : amount, color : color!)
                dataArrayExpense.append(data)
            } else {
                let data  = DataGraph(name : nameModePaiement!, value : amount, color : color!)
                dataArrayIncome.append(data)
            }
        }

        self.depenseArray.removeAll()
        let allKeys = Set<String>(depenseArray.map { $0.name })
        for key in allKeys {
            let data = dataArrayExpense.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            self.depenseArray.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        self.depenseArray = self.depenseArray.sorted(by: { $0.name < $1.name })
        
        recetteArray.removeAll()
        let allKeysR = Set<String>(recetteArray.map { $0.name })
        for key in allKeysR {
            let data = dataArrayIncome.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            recetteArray.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        recetteArray = recetteArray.sorted(by: { $0.name < $1.name })
        
        self.depenseArray = summarizeData(from: dataArrayExpense, maxCategories: 6)
        self.recetteArray = summarizeData(from: dataArrayIncome, maxCategories: 6)
        
        self.dataEntriesDepense = pieChartEntries(from: depenseArray)
        self.dataEntriesRecette = pieChartEntries(from: recetteArray)

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


//
//  ModePaiementPie2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct ModePaiementPieView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
//        ModePaiementView()
//            .task {
//                await performFalseTask()
//            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}


//
//  ModePaiementPie3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct ModePaiementView: View {

    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = ModePaymentPieViewModel()

    let transactions: [EntityTransaction]

    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @Binding var minDate: Date
    @Binding var maxDate: Date

    private var firstDate: Date {
        transactions.first?.dateOperation ?? Date()
    }

    private var lastDate: Date {
        transactions.last?.dateOperation ?? Date()
    }

    private var durationDays: Double {
        lastDate.timeIntervalSince(firstDate) / 86400
    }

    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: PieChartView?
    @State private var updateWorkItem: DispatchWorkItem?
    
    @State private var lower: Double = 2
    @State private var upper: Double = 10


    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ModePaiement Pie")
                .font(.headline)
                .padding()
            
            HStack {
                SinglePieChartView(entries: viewModel.dataEntriesDepense, title: "Dépenses")
                    .frame(width: 600, height: 400)
                    .padding()
                
                SinglePieChartView(entries: viewModel.dataEntriesRecette, title: "Recettes")
                    .frame(width: 600, height: 400)
                    .padding()
            }
            
            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        lowerValue: $lower,
                        upperValue: $upper,
                        totalRange: 0...30,
                        valueLabel: { value in
                            let today = Date()
                            let date = Calendar.current.date(byAdding: .day, value: Int(value), to: today)!
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            return formatter.string(from: date)
                        },
                        thumbSize: 24,
                        trackHeight: 6
                    )
                        .frame(height: 30)

                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }

        }
        .onAppear {
            let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
            let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
            let currentAccount = CurrentAccountManager.shared.getAccount()!
            viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
        }
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}
