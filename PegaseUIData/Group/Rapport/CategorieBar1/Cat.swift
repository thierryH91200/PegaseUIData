//
//  Cat.swift
//  PegaseUIData
//
//  Created by thierryH24 on 18/09/2025.
//

//

import SwiftUI
import SwiftData
import DGCharts
import Combine
import UniformTypeIdentifiers
import AppKit


struct CategorieBar1View: View {
    
    @Binding var isVisible: Bool
    @Binding var executed: Double
    @Binding var planned: Double
    @Binding var engaged: Double

    @State private var transactions: [EntityTransaction] = []
    @State private var allTransactions: [EntityTransaction] = []
    
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()

    
    var body: some View {
        
        SummaryView(
            planned: planned,
            engaged: engaged,
            executed: executed
        )

        CategorieBar1View1(transactions: transactions,
                           allTransactions: $allTransactions,
                           lowerValue: $lowerValue,
                           upperValue: $upperValue,
                           minDate: $minDate,
                           maxDate: $maxDate)
            .task {
                await performFalseTask()
            }
            .onAppear {
                transactions = ListTransactionsManager.shared.getAllData()
                allTransactions = transactions
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

struct CategorieBar1View1: View {
    
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @StateObject private var viewModel = CategorieBar1ViewModel()
    
    let transactions: [EntityTransaction]
    
    @Binding var allTransactions: [EntityTransaction]
    @State var filteredTransactions: [EntityTransaction] = []
    
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
    private let oneDay = 3600.0 * 24.0 // one day
    
    @State private var chartView: BarChartView?
    
    @State private var lower: Double = 2
    @State private var upper: Double = 10

    var body: some View {
        VStack {
            Text("CategorieBar1View1")
                .font(.headline)
                .padding()
            
            Text("Total: \(viewModel.totalValue, format: .currency(code: viewModel.currencyCode))")
                .font(.title3)
                .bold()
                .padding(.bottom, 4)
            
            if !viewModel.labels.isEmpty {
                DisclosureGroup("Visible categories") {
                    Button(viewModel.selectedCategories.count < viewModel.labels.count ? "All select" : "Deselect all") {
                        if viewModel.selectedCategories.count < viewModel.labels.count {
                            viewModel.selectedCategories = Set(viewModel.labels)
                        } else {
                            viewModel.selectedCategories.removeAll()
                        }
                        updateChart()
                    }
                    .font(.caption)
                    .padding(.bottom, 4)
                    
                    ForEach(viewModel.labels, id: \.self) { label in
                        Toggle(label, isOn: Binding(
                            get: { viewModel.selectedCategories.isEmpty || viewModel.selectedCategories.contains(label) },
                            set: { newValue in
                                if newValue {
                                    viewModel.selectedCategories.insert(label)
                                } else {
                                    viewModel.selectedCategories.remove(label)
                                }
                                updateChart()
                            }
                        ))
                    }
                }
                .padding()
            }
            Button("Export to PNG") {
                exportChartAsImage()
            }
            .padding(.bottom, 8)
            
            DGBarChart1Representable(viewModel: viewModel,
                                     entries: viewModel.dataEntries)
            .frame(width: 600, height: 400)
            .padding()
            .onAppear {
                viewModel.updateAccount(minDate: minDate)
            }

            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        lowerValue: $lower,
                        upperValue: $upper,
                        totalRange: lower...upper,
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
                        .frame(height: 50)
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
            .padding()
            Spacer()
        }
        .onAppear {
            
            let listTransactions = ListTransactionsManager.shared.getAllData()
            minDate = listTransactions.first!.dateOperation
            maxDate = listTransactions.last!.dateOperation
            selectedEnd = maxDate.timeIntervalSince(minDate) / oneDay

            chartView = BarChartView()
            if let chartView = chartView {
                CategorieBar1ViewModel.shared.configure(with: chartView)
            }
            updateChart()
        }
        
        .onChange(of: selectedStart) { _, newStart in
            viewModel.selectedStart = newStart
            updateChart()
        }
        .onChange(of: selectedEnd) { _, newEnd in
            viewModel.selectedEnd = newEnd
            updateChart()
        }
    }
    
    func applyFilter() {
        guard !allTransactions.isEmpty else {
            filteredTransactions = []
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: Int(lowerValue), to: minDate) ?? minDate
        let endDate = Calendar.current.date(byAdding: .day, value: Int(upperValue), to: minDate) ?? maxDate
        
        filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }
    }


    private func updateChart() {
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!


        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData( startDate: start, endDate: end)
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func exportChartAsImage() {
        guard let chartView = chartView else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Graphique.png"
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            if let image = chartView.getChartImage(transparent: false),
               let rep = NSBitmapImageRep(data: image.tiffRepresentation!),
               let pngData = rep.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }

    private func findChartView(in window: NSWindow?) -> BarChartView? {
        guard let views = window?.contentView?.subviews else { return nil }
        for view in views {
            if let chart = view.subviews.compactMap({ $0 as? BarChartView }).first {
                return chart
            }
        }
        return nil
    }
}

class CategorieBar1ViewModel: ObservableObject {
    
    @Published var listTransactions : [EntityTransaction] = []
    
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    @Published var selectedCategories: Set<String> = []
    
    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0
    
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    var chartView : BarChartView?
    var rangeSlider : RangeSlider?

    static let shared = CategorieBar1ViewModel()
    
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
    
    func configure(with chartView: BarChartView)
    {
        self.chartView = chartView
    }

    
    func updateAccount(minDate: Date) {
        let transactions = ListTransactionsManager.shared.getAllData()

        DispatchQueue.main.async {
            self.listTransactions = transactions
            if let first = transactions.first?.dateOperation.timeIntervalSince1970,
               let last = transactions.last?.dateOperation.timeIntervalSince1970 {
                self.firstDate = first
                self.lastDate = last
            }
        }
    }

    func updateChartData( startDate: Date, endDate: Date) {
        // Configure the transaction manager with context if needed

        // Fetch transactions in the requested range
        self.listTransactions = ListTransactionsManager.shared.getAllData(from: startDate, to: endDate)

        guard !listTransactions.isEmpty else {
            self.resultArray = []
            self.dataEntries = []
            return
        }

        // Build flat data from sousOperations
        var dataArray: [DataGraph] = []
        for transaction in listTransactions {
            let sousOperations = transaction.sousOperations
            for sousOperation in sousOperations {
                if let rubric = sousOperation.category?.rubric {
                    let name = rubric.name
                    let value = sousOperation.amount
                    let color = rubric.color
                    dataArray.append(DataGraph(name: name, value: value, color: color))
                }
            }
        }

        // Group by name and sum values
        let allKeys = Set(dataArray.map { $0.name })
        var results: [DataGraph] = []
        for key in allKeys {
            let data = dataArray.filter { $0.name == key }
            let sum = data.map { $0.value }.reduce(0, +)
            if let color = data.first?.color {
                results.append(DataGraph(name: key, value: sum, color: color))
            }
        }

        // Apply category filter if any
        var filteredResults = results
        if !selectedCategories.isEmpty {
            filteredResults = results.filter { selectedCategories.contains($0.name) }
        }

        // Sort and publish
        let sorted = filteredResults.sorted { $0.name < $1.name }
        self.resultArray = sorted

        // Build chart entries
        var entries: [BarChartDataEntry] = []
        for (i, item) in sorted.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
        }
        self.dataEntries = entries
    }
}



struct DGBarChart1Representable: NSViewRepresentable {
    
    @ObservedObject var viewModel: CategorieBar1ViewModel
    let entries: [BarChartDataEntry]
    
    let hourSeconds = 3600.0 * 24.0 // one day

    func makeNSView(context: Context) -> BarChartView {

        let chartView = BarChartView()
        initChart(on: chartView)
        return chartView
    }

    func updateNSView(_ nsView: BarChartView, context: Context) {
        DispatchQueue.main.async {
            let newData = self.viewModel.resultArray
            self.setData(on: nsView, with: newData)
        }
    }
    
    func setData(on chartView: BarChartView, with data: [DataGraph]) {
        // If there's no data, clear the chart and return
        guard !data.isEmpty else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return
        }

        // Build entries and colors
        var entries: [BarChartDataEntry] = []
        var colors: [NSColor] = []
        var labels: [String] = []

        for (i, item) in data.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
            labels.append(item.name)
            colors.append(item.color)
        }

        // Configure xAxis labels
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelCount = labels.count

        // Create or update dataset
        if chartView.data == nil {
            let dataSet = BarChartDataSet(entries: entries, label: "Rubric")
            dataSet.colors = colors
            dataSet.drawValuesEnabled = true
            dataSet.barBorderWidth = 0.1
            dataSet.valueFormatter = DefaultValueFormatter(formatter: viewModel.formatterPrice)

            let barData = BarChartData(dataSets: [dataSet])
            barData.setValueFormatter(DefaultValueFormatter(formatter: viewModel.formatterPrice))
            barData.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
            barData.setValueTextColor(NSColor.labelColor)

            chartView.data = barData
        } else {
            if let set1 = chartView.data?.dataSets.first as? BarChartDataSet {
                set1.colors = colors
                set1.replaceEntries(entries)
            }
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
    
    func initChart(on chartView: BarChartView) {
        
        chartView.xAxis.valueFormatter = CurrencyValueFormatter()
        
        // MARK: General
        chartView.drawBarShadowEnabled      = false

        chartView.drawValueAboveBarEnabled  = true
        chartView.maxVisibleCount           = 60
        chartView.drawGridBackgroundEnabled = true
        chartView.drawBordersEnabled        = true
        chartView.gridBackgroundColor       = .windowBackgroundColor
        chartView.fitBars                   = true

        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = String(localized:"No chart data available.")
        
        // MARK: Axis
        setUpAxis(chartView: chartView)
        
        // MARK: Legend
        initializeLegend(chartView.legend)
        chartView.legend.enabled = false
        
        // MARK: Description
        let bounds                           = chartView.bounds
        let point    = CGPoint( x: bounds.width / 2, y: bounds.height * 0.25)
        chartView.chartDescription.enabled  = true
        chartView.chartDescription.text     = "Rubric"
        chartView.chartDescription.position = point
        chartView.chartDescription.font     = NSFont(name: "HelveticaNeue-Light", size: CGFloat(24.0))!
    }
    
    func initializeLegend(_ legend: Legend) {
        
        legend.horizontalAlignment           = .left
        legend.verticalAlignment             = .top
        legend.orientation                   = .vertical
        legend.drawInside                    = true
        legend.form                          = .square
        legend.formSize                      = 9.0
        legend.font                          = NSFont.systemFont(ofSize: CGFloat(11.0))
        legend.xEntrySpace                   = 4.0
    }
    
    func setUpAxis(chartView: BarChartView) {
        // MARK: xAxis
        let xAxis                      = chartView.xAxis
        xAxis.labelPosition            = .bottom
        xAxis.labelFont                = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        xAxis.drawGridLinesEnabled     = true
        xAxis.granularity              = 1
        xAxis.enabled                  = true
        xAxis.labelTextColor           = .labelColor
        xAxis.labelCount               = 10
        xAxis.valueFormatter           = CurrencyValueFormatter()

        // MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont             = NSFont(name: "HelveticaNeue-Light", size: CGFloat(10.0))!
        leftAxis.labelCount            = 12
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        leftAxis.labelTextColor        = .labelColor

        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
    }
    
}
