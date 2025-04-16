//
//  ModePaiementView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import SwiftData
import DGCharts

class ModePaymentPieViewModel: ObservableObject {
    @Published var resultArrayExpense: [DataGraph] = []
    @Published var resultArrayIncome: [DataGraph] = []
    @Published var dataEntries: [PieChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
    var labelsExpense: [String] {
        resultArrayExpense.map { $0.name }
    }
    var labelsIncome: [String] {
        resultArrayIncome.map { $0.name }
    }

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    
    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {

        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome = [DataGraph]()
        
//        (startDate, endDate) = (sliderViewController?.calcStartEndDate())!
        
        let sort = [SortDescriptor(\EntityTransactions.dateOperation, order: .reverse)]
        let lhs = currentAccount!.uuid

        let descriptor = FetchDescriptor<EntityTransactions>(
            predicate: #Predicate { transaction in
                transaction.account.uuid == lhs &&
                transaction.dateOperation >= startDate &&
                transaction.dateOperation <= endDate
            },
            sortBy: sort
        )

        var listTransactions: [EntityTransactions] = []

        do {
            listTransactions = try modelContext.fetch(descriptor)
            
        } catch {
            print("Error fetching data from CoreData")
        }
        
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

        self.resultArrayExpense.removeAll()
        let allKeys = Set<String>(dataArrayExpense.map { $0.name })
        for key in allKeys {
            let data = dataArrayExpense.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            self.resultArrayExpense.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        self.resultArrayExpense = self.resultArrayExpense.sorted(by: { $0.name < $1.name })
        
        resultArrayIncome.removeAll()
        let allKeysR = Set<String>(dataArrayIncome.map { $0.name })
        for key in allKeysR {
            let data = dataArrayIncome.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            resultArrayIncome.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        resultArrayIncome = resultArrayIncome.sorted(by: { $0.name < $1.name })
    }
}

struct ModePaiementPieView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        ModePaiementView()
            .task {
                await performFalseTask()
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

struct DGPieChart3View3: NSViewRepresentable {
    
    let entries: [PieChartDataEntry]
    @State var chartView1 : PieChartView = PieChartView()
    @State var chartView2 : PieChartView = PieChartView()
    
    @Binding var chartViewRef: PieChartView?

    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = PieChartDataSet(entries: entries, label: "Mode Payment Pie1")
        dataSet.colors = ChartColorTemplates.colorful()
        
        let data = PieChartData(dataSet: dataSet)
        chartView.data = data
        
        self.chartView1.spin(duration: 1, fromAngle: 0, toAngle: 360.0)
        self.chartView2.spin(duration: 1, fromAngle: 0, toAngle: 360.0)

        return chartView
    }
    
    func updateNSView(_ nsView: PieChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
    
    func initChart() {
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        
        let attribut: [ NSAttributedString.Key: Any] =
        [ .font: NSFont(name: "HelveticaNeue-Light", size: 15.0)!,
          .foregroundColor: NSColor.textColor,
          .paragraphStyle: paragraphStyle]
        
        // MARK: - Chart View Depense
        var centerText = NSMutableAttributedString(string: "Expenses")
        centerText.setAttributes(attribut, range: NSRange(location: 0, length: centerText.length))
        chartView1.centerAttributedText = centerText
        chartView1.chartDescription.enabled = false
        chartView1.noDataText = String(localized:"No chart data available.")
        chartView1.holeColor = .windowBackgroundColor
        chartView1.setExtraOffsets(left: 0, top: 0, right: 100, bottom: 0)
        
        // MARK: legend
        initializeLegend2(chartView1.legend)
        
        // MARK: - Chart View2 Income
        centerText = NSMutableAttributedString(string: "Income")
        centerText.setAttributes(attribut, range: NSRange(location: 0, length: centerText.length))
        
        chartView2.centerAttributedText = centerText
        chartView2.chartDescription.enabled = false
        chartView2.noDataText = String(localized:"No chart data available.")
        chartView2.holeColor = .windowBackgroundColor
        
        // MARK: legend
        initializeLegend2(chartView2.legend)
    }
    
    func initializeLegend1(_ legend: Legend) {
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        legend.textColor = .labelColor
        legend.enabled = false

    }

    func initializeLegend2(_ legend: Legend) {
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        legend.textColor = .labelColor
        legend.enabled = false
    }
}

struct ModePaiementView: View {

    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = ModePaymentPieViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: PieChartView?
    @State private var updateWorkItem: DispatchWorkItem?


    var body: some View {
        VStack {
            Text("ModePaiementView")
                .font(.headline)
                .padding()
            DGPieChart3View3(entries: viewModel.dataEntries,
//                             labels: viewModel.labelsIncome,
                             chartViewRef: $chartViewRef)
                .frame(width: 600, height: 400)
                .padding()
            Spacer()
        }
        .onAppear {
            let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
            let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
            let currentAccount = CurrentAccountManager.shared.getAccount()!
            viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
        }

    }
}
