import SwiftUI
import DGCharts

struct DGBarChart7Representable: NSViewRepresentable {
    
    @ObservedObject var viewModel: CategorieBar1ViewModel

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.delegate = context.coordinator
        configure(chartView)
        viewModel.configure(with: chartView)
        return chartView
    }

    func updateNSView(_ chartView: BarChartView, context: Context) {
        // Data is pushed from the ViewModel via setDataCount()
        // Keep axis label formatter in sync if needed (handled by ViewModel when setting data)
    }

    final class Coordinator: NSObject, ChartViewDelegate {
        
        var parent: DGBarChart7Representable
        init(parent: DGBarChart7Representable) { self.parent = parent }

        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            // Identify rubric and month index
            let dataSetIndex = Int(highlight.dataSetIndex)
            let barX = Int(floor(entry.x))

            // Resolve rubric name from dataset label
            var rubricName: String = ""
            if let dataSet = chartView.data?.dataSets[safe: dataSetIndex] {
                rubricName = dataSet.label ?? ""
            }
            guard !rubricName.isEmpty else { return }

            // Resolve month (section) key using the ViewModel's section order
            guard parent.viewModel.sectionOrder.indices.contains(barX) else { return }
            let sectionKey = parent.viewModel.sectionOrder[barX]

            // Filter manager list to the selected month and rubric
            let full = ListTransactionsManager.shared.getAllData()
            let filtered: [EntityTransaction] = full.filter { tx in
                guard let sec = tx.sectionIdentifier else { return false }
                guard sec == sectionKey else { return false }
                return tx.sousOperations.contains { $0.category?.rubric?.name == rubricName }
            }

            // Publish
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

        func chartValueNothingSelected(_ chartView: ChartViewBase) {
            // When nothing selected, clear the filtered list
            DispatchQueue.main.async {
                var didChange = false
                if !ListTransactionsManager.shared.listTransactions.isEmpty {
                    ListTransactionsManager.shared.listTransactions = []
                    didChange = true
                }
                if didChange {
                    NotificationCenter.default.post(name: .transactionsSelectionChanged, object: nil)
                }
            }
        }
    }

    private func configure(_ chartView: BarChartView) {
        // General
        chartView.drawBarShadowEnabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.maxVisibleCount = 60
        chartView.drawBordersEnabled = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor = .windowBackgroundColor
        chartView.fitBars = true
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.noDataText = String(localized: "No chart data available.")
        chartView.highlightPerTapEnabled = true
        chartView.highlightFullBarEnabled = false

        // xAxis
        let xAxis = chartView.xAxis
        xAxis.labelFont = NSFont.systemFont(ofSize: 14, weight: .light)
        xAxis.drawGridLinesEnabled = true
        xAxis.enabled = true
        xAxis.labelTextColor = .labelColor

        xAxis.labelPosition = .bottom
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1

        // leftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.labelFont = NSFont.systemFont(ofSize: 10, weight: .light)
        leftAxis.labelCount = 12
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        leftAxis.granularity = 1
        leftAxis.valueFormatter = CurrencyValueFormatter()
        leftAxis.labelTextColor = .labelColor

        // rightAxis
        chartView.rightAxis.enabled = false

        // legend
        let legend = chartView.legend
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.font = NSFont.systemFont(ofSize: 14, weight: .light)
        legend.textColor = .labelColor

        // description
        chartView.chartDescription.enabled = false
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
