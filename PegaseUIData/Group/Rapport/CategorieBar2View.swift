//
//  CategorieBar2View.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import SwiftData
import DGCharts

class CategorieBar2ViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
    var labels: [String] {
        resultArray.map { $0.name }
    }

    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date)
    {
        guard let currentAccount else { return }
        self.currencyCode = currentAccount.currencyCode
        var arrayUniqueRubriques   = [RubricColor]()

//        (startDate, endDate) = (sliderViewController?.calcStartEndDate())!
        
        let sort = [SortDescriptor(\EntityTransactions.dateOperation, order: .reverse)]
        let lhs = currentAccount.uuid
        
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
            print("Erreur lors de la récupération des transactions :", error)
            return
        }

        // Récupere le nom de toutes les rubriques
        // Récupere les datas pour la période choisie
        var setUniqueRubrique     = Set<RubricColor>()
        var dataRubrique = [DataGraph]()
        
        for listTransaction in listTransactions {
            
            let id = listTransaction.sectionIdentifier!
            
            let sousOperations = listTransaction.sousOperations
            for sousOperation in sousOperations {
                
                let amount    = sousOperation.amount
                
                let nameRubric = sousOperation.category?.rubric?.name
                let color    = sousOperation.category?.rubric?.color
                let rubricColor = RubricColor(name : nameRubric!, color: color!)
                
                setUniqueRubrique.insert(rubricColor)
                
                let data = DataGraph(section: id, name: nameRubric!, value: amount, color: color!)
                dataRubrique.append( data)
            }
        }
        arrayUniqueRubriques = setUniqueRubrique.sorted { $0.name > $1.name }
        
        // sum per rubric for each period
        resultArray.removeAll()
        let allRubricKeys = Set<String>(dataRubrique.map { $0.section })
        for keyRubric in allRubricKeys {
            for dataRubric in arrayUniqueRubriques {
                let data = dataRubrique.filter({ $0.section == keyRubric && $0.name == dataRubric.name  })
                if data.isEmpty == false {
                    let sum = data.map({ $0.value }).reduce(0, +)
                    resultArray.append(DataGraph(section: keyRubric ,name: dataRubric.name, value: sum, color: dataRubric.color))
                } else {
                    resultArray.append(DataGraph(section: keyRubric ,name: dataRubric.name, value: 0, color: dataRubric.color))
                }
            }
        }
        resultArray = resultArray.sorted(by: { $0.name < $1.name })
        resultArray = resultArray.sorted(by: { $0.section < $1.section })
        
        var entries: [BarChartDataEntry] = []
        for (i, item) in self.resultArray.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
        }
        self.dataEntries = entries
    }
}

struct CategorieBar2View: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        CategorieBar2View2()
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

struct CategorieBar2View2: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = CategorieBar2ViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()

    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: BarChartView?
    @State private var updateWorkItem: DispatchWorkItem?


    var body: some View {
        VStack {
            Text("CategorieBar2View2")
                .font(.headline)
                .padding()
            
            DGBarChartView(entries: viewModel.dataEntries,
                           labels: viewModel.labels,
                           chartViewRef: $chartViewRef)
                .frame(width: 600, height: 400)
                .padding()
            RangeSlider(minValue: 0,
                        maxValue: maxDate.timeIntervalSince(minDate) / (60 * 60 * 24),
                        lowerValue: $selectedStart,
                        upperValue: $selectedEnd)
                .frame(height: 30)

            Spacer()
        }
        .onAppear {
            let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
            let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
            let currentAccount = CurrentAccountManager.shared.getAccount()!
            viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
        }
        
        .onChange(of: selectedStart) { _, newValue in
            print("🎚️ selectedStart: \(newValue)")
            updateChartDebounced()
        }
        
        .onChange(of: selectedEnd) { _, newValue in
            print("🎚️ selectedEnd: \(newValue)")
            updateChartDebounced()
        }
    }
    
    func updateChartDebounced() {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem { self.updateChart() }
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func updateChart() {
        print("🟦 Mise à jour du graphique")
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }
}

struct RubricColor : Hashable {
    var name: String
    var color  : NSColor
    
    init(name:String, color : NSColor) {
        self.name = name
        self.color = color
    }
}

struct DGBarChart2View2: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    let labels: [String]
    @Binding var chartViewRef: BarChartView?
    
    @Environment(\.modelContext) var modelContext
    
    @State var chartView : BarChartView = BarChartView()
    @State var resultArray = [DataGraph]()
    @State var label  = [String]()
    
    @State var numericIDs  = [String]()
    var arrayUniqueRubriques   = [RubricColor]()

    
    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    let formatterDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM/yyyy", options: 0, locale: Locale.current)
        return fmt
    }()
    
    func makeNSView(context: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        
        let data = BarChartData(dataSet: dataSet)
        chartView.data = data
        
        // Personnalisation du graphique
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.animate(yAxisDuration: 1.5)
        
        return chartView
    }
    
    func updateNSView(_ nsView: BarChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
    
    private func initChart() {
        
        // MARK: General
        chartView.borderColor = .controlBackgroundColor
        chartView.gridBackgroundColor = .gridColor
        chartView.drawBarShadowEnabled      = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.maxVisibleCount           = 60
        chartView.drawGridBackgroundEnabled = true
        //        chartView.backgroundColor = .windowBackgroundColor
        chartView.gridBackgroundColor = .windowBackgroundColor
        
        chartView.fitBars                   = true
        chartView.drawBordersEnabled = true
        
        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = String(localized:"No chart data available.")
        
        // MARK: xAxis
        let xAxis                      = chartView.xAxis
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity              = 1.0
        xAxis.gridLineWidth = 2.0
        xAxis.labelCount = 20
        xAxis.labelFont                = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        xAxis.labelPosition            = .bottom
        xAxis.labelTextColor           = .labelColor
        
        // MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont             = NSFont(name: "HelveticaNeue-Light", size: CGFloat(10.0))!
        leftAxis.labelTextColor        = .labelColor
        
        leftAxis.labelCount            = 10
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        
        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
        
        // MARK: legend
        initializeLegend(chartView.legend)
        
        // MARK: description
        chartView.chartDescription.enabled  = false
        
    }
    
    func initializeLegend(_ legend: Legend) {
        legend.horizontalAlignment           = .left
        legend.verticalAlignment             = .bottom
        legend.orientation                   = .vertical
        legend.drawInside                    = false
        legend.form                          = .square
        legend.formSize                      = 9.0
        legend.font                          = NSFont.systemFont(ofSize: CGFloat(11.0))
        legend.xEntrySpace                   = 4.0
        legend.textColor = NSColor.labelColor
        legend.enabled = true
        
    }
    
    private func setDataCount()
    {
        guard resultArray.isEmpty == false else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return }
        
        let groupSpace = 0.2
        let barSpace = 0.0
        let barWidth = Double(0.8 / Double(arrayUniqueRubriques.count))
        
        // MARK: BarChartDataEntry
        var entries = [BarChartDataEntry]()
        
        // MARK: ChartDataSet
        let dataSets = (0 ..< arrayUniqueRubriques.count).map { (i) -> BarChartDataSet in
            
            let dataRubrique = resultArray.filter({ $0.name == arrayUniqueRubriques[i].name  })
            entries.removeAll()
            for i in 0 ..< dataRubrique.count {
                entries.append(BarChartDataEntry(x: Double(i), y: abs(dataRubrique[i].value)))
            }
            
            let dataSet = BarChartDataSet(entries: entries, label: dataRubrique[0].name)
            dataSet.colors = [dataRubrique[0].color]
            dataSet.drawValuesEnabled = false
            return dataSet
        }
        
        let allKeyIDs = Set<String>(resultArray.map { $0.section })
        self.numericIDs = allKeyIDs.sorted(by: { $0 < $1 })
        var labelDate = [String]()
        
        for numericID in self.numericIDs {
            let numericSection = Int(numericID)
            var components = DateComponents()
            components.year = numericSection! / 100
            components.month = numericSection! % 100
            let date = Calendar.current.date(from: components)
            let dateString = formatterDate.string(from: date!)
            labelDate.append(dateString)
        }
        
        // MARK: BarChartData
        let data = BarChartData(dataSets: dataSets)
        
        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
        data.setValueTextColor(NSColor.black)
        
        data.barWidth = barWidth
        data.groupBars( fromX: Double(0), groupSpace: groupSpace, barSpace: barSpace)
        
        let groupCount = allKeyIDs.count + 1
        let startYear = 0
        let endYear = startYear + groupCount
        
        self.chartView.xAxis.axisMinimum = Double(startYear)
        self.chartView.xAxis.axisMaximum = Double(endYear)
        self.chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labelDate)
        
        self.chartView.data = data
        
    }
}


