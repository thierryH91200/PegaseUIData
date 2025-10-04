////
////  RecetteDepenseBar4.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
import SwiftUI
import SwiftData
import DGCharts
import Combine
import SwiftDate

struct DGBarChart4Representable: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    let title: String
    let labels: [String]
    let data : BarChartData?
    
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    
    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    let formatterDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM yy", options: 0, locale: Locale.current)
        return fmt
    }()

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> BarChartView {
        
        let chartView = BarChartView()

        chartView.delegate = context.coordinator
        
        configure(chartView)
        if let chartData = makeChartData() {
            chartView.data = chartData
        } else {
            chartView.data = nil
        }

        return chartView
    }
    
    func updateNSView(_ chartView: BarChartView, context: Context) {
        context.coordinator.parent = self

        // Keep axis config in sync
        let xAxis = chartView.xAxis
        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        xAxis.axisMinimum = -0.25
        xAxis.axisMaximum = Double(labels.count) + 0.25

        let chartData = makeChartData()
        chartView.data = chartData
        chartView.fitBars = true
        DispatchQueue.main.async {
            chartData?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
    
    private func makeChartData() -> BarChartData? {
        if let provided = data {
            return provided
        }
        guard !entries.isEmpty else { return nil }
        let dataSet = BarChartDataSet(entries: entries, label: title)
        dataSet.colors = ChartColorTemplates.colorful()
        return BarChartData(dataSet: dataSet)
    }
    
    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: DGBarChart4Representable
        var isUpdating = false
        var fullFilteredCache: [EntityTransaction] = []

        init(parent: DGBarChart4Representable) {
            self.parent = parent
        }

        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            let i = Int(round(highlight.x))
            guard i >= 0, i < parent.labels.count else { return }

            let dataSetIndex = Int(highlight.dataSetIndex)
            printTag("index: \(i), entryX: \(entry.x), dataSetIndex: \(dataSetIndex) ")

            // Compute the current range window based on lower/upper values (in days) from the dataset min date
            let all = ListTransactionsManager.shared.getAllData()
            guard let globalMin = all.min(by: { $0.dateOperation < $1.dateOperation })?.dateOperation else { return }
            let cal = Calendar.current
            let rangeStart = cal.date(byAdding: .day, value: Int(parent.lowerValue), to: globalMin) ?? globalMin
            let rangeEndExclusive = cal.date(byAdding: .day, value: Int(parent.upperValue + 1), to: globalMin) ?? globalMin

            // Build the current range-filtered list and cache it for restoration on deselection
            let fullFiltered = all.filter { tx in
                tx.dateOperation >= rangeStart && tx.dateOperation < rangeEndExclusive
            }
            self.fullFilteredCache = fullFiltered

            // Derive the selected month interval from the index relative to the range start's month
            let baseMonthStart = rangeStart.startOfMonth()
            let derived = cal.date(byAdding: .month, value: i, to: baseMonthStart) ?? baseMonthStart
            let monthStart = derived.startOfMonth()
            let monthEndExclusive = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart

            // First, filter by the selected month range
            let monthFiltered = fullFiltered.filter { tx in
                tx.dateOperation >= monthStart && tx.dateOperation < monthEndExclusive
            }

            // Then, filter by sign depending on the selected dataset:
            // dataSetIndex == 0 -> amount < 0 (expenses)
            // dataSetIndex == 1 -> amount > 0 (income)
            let filtered: [EntityTransaction]
            switch dataSetIndex {
            case 0:
                filtered = monthFiltered.filter { $0.amount < 0 }
            case 1:
                filtered = monthFiltered.filter { $0.amount > 0 }
            default:
                filtered = monthFiltered
            }

            // Publish the filtered list to the shared manager and notify the UI
            DispatchQueue.main.async {
                var didChange = false
                if ListTransactionsManager.shared.listTransactions != filtered {
                    ListTransactionsManager.shared.listTransactions = filtered
                    didChange = true
                }
                if didChange {
                    NotificationCenter.default.post(name: .transactionsSelectionChanged, object: nil)
                }
            }
        }
        
        public func chartValueNothingSelected(_ chartView: ChartViewBase) {
            let restored = self.fullFilteredCache
            self.fullFilteredCache.removeAll()
            DispatchQueue.main.async {
                var didChange = false
                if ListTransactionsManager.shared.listTransactions != restored {
                    ListTransactionsManager.shared.listTransactions = restored
                    didChange = true
                }
                if didChange {
                    NotificationCenter.default.post(name: .transactionsSelectionChanged, object: nil)
                }
            }
        }
    }

    private func configure(_ chartView: BarChartView) {
            
        // MARK: General
        chartView.drawBarShadowEnabled      = false
        chartView.drawValueAboveBarEnabled  = true
        chartView.maxVisibleCount           = 60
        chartView.drawBordersEnabled        = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor       = .windowBackgroundColor
        chartView.fitBars                   = true
//        chartView.highlightPerTapEnabled   = true
        
        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = String(localized: "No chart data available.")
        
        // MARK: xAxis
        let xAxis            = chartView.xAxis
        xAxis.drawGridLinesEnabled    = true
        xAxis.gridLineWidth = 2.0
        xAxis.labelCount = 20
        xAxis.labelFont = NSFont.systemFont(ofSize: 14, weight: .light)
        xAxis.labelTextColor = .labelColor
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1
        xAxis.labelPosition = .top
        
        xAxis.axisMinimum = -0.25
        xAxis.axisMaximum = Double(labels.count) + 0.25

        // MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont = NSFont.systemFont(ofSize: 10, weight: .light)
        leftAxis.labelCount            = 6
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        leftAxis.labelTextColor        = .labelColor
        
        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
        
        // MARK: legend
        let legend = chartView.legend
        legend.horizontalAlignment = .right
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside                    = true
        legend.xOffset = 10.0
        legend.yEntrySpace = 0.0
        legend.font = NSFont.systemFont(ofSize: 11, weight: .light)
        legend.textColor = .labelColor
        
        // MARK: description
        chartView.chartDescription.enabled  = false
    }
}

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: 0), to: self.startOfMonth())!
    }
}

