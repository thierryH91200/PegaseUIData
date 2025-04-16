import SwiftUI
import SwiftData
import DGCharts

class CategorieBar1ViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
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

    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
        
        guard let currentAccount else { return }
        self.currencyCode = currentAccount.currencyCode

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

        let allKeys = Set(dataArray.map { $0.name })
        var results: [DataGraph] = []
        for key in allKeys {
            let data = dataArray.filter { $0.name == key }
            let sum = data.map { $0.value }.reduce(0, +)
            if let color = data.first?.color {
                results.append(DataGraph(name: key, value: sum, color: color))
            }
        }

        var filteredResults = results
        if !selectedCategories.isEmpty {
            filteredResults = results.filter { selectedCategories.contains($0.name) }
        }
        self.resultArray = filteredResults.sorted { $0.name < $1.name }

        var entries: [BarChartDataEntry] = []
        for (i, item) in self.resultArray.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
        }
        self.dataEntries = entries
    }
}

struct CategorieBar1View: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        CategorieBar1View1()
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

struct CategorieBar1View1: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = CategorieBar1ViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: BarChartView?
    
    @State private var updateWorkItem: DispatchWorkItem?

    // À remplacer par le vrai compte utilisateur si disponible
    let currentAccount: EntityAccount? = nil

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
                DisclosureGroup("Catégories visibles") {
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
            Button("Exporter en PNG") {
                exportChartAsImage()
            }
            .padding(.bottom, 8)
            
            DGBarChartView(entries: viewModel.dataEntries,
                           labels: viewModel.labels,
                           chartViewRef: $chartViewRef)
                .frame(width: 600, height: 400)
                .padding()

            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(minValue: 0,
                                maxValue: maxDate.timeIntervalSince(minDate) / (60 * 60 * 24),
                                lowerValue: $selectedStart,
                                upperValue: $selectedEnd)
                        .frame(height: 30)
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
            .padding()
            
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
    
    private func exportChartAsImage() {
        guard let chartView = chartViewRef else { return }

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
    
    private func updateChart() {
        print("🟦 Mise à jour du graphique")
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DGBarChartView: NSViewRepresentable {
    let entries: [BarChartDataEntry]
    let labels: [String]
    @Binding var chartViewRef: BarChartView?
    
    @Environment(\.modelContext) var modelContext
    
    @State var chartView : BarChartView = BarChartView()
    @State var resultArray = [DataGraph]()
    @State var label  = [String]()

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func makeNSView(context: Context) -> BarChartView {
        let chartView = BarChartView()

        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()

        let data = BarChartData(dataSet: dataSet)
        chartView.data = data

        // Personnalisation du graphique
        initChart()
        chartView.animate(yAxisDuration: 1.5)
        
        DispatchQueue.main.async {
            self.chartViewRef = chartView
        }
        return chartView
    }

    func updateNSView(_ nsView: BarChartView, context: Context) {
        // Crée un nouveau DataSet avec les nouvelles entrées
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        dataSet.drawValuesEnabled = true
 
        let data = BarChartData(dataSet: dataSet)
        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
        data.setValueTextColor(NSColor.black)
 
        nsView.data = data
        nsView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()

    }
    
    func initChart() {
        chartView.xAxis.valueFormatter = CurrencyValueFormatter()
        
        // MARK: General
//        chartView.delegate = self
        
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
        setUpAxis()
        
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
    
    func setUpAxis() {
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
    
    func setDataCount()
    {
        guard resultArray.isEmpty == false else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return }

        // MARK: BarChartDataEntry
        var entries = [BarChartDataEntry]()
        var colors = [NSColor]()
        label.removeAll()
        colors.removeAll()

        for i in 0 ..< resultArray.count {
            entries.append(BarChartDataEntry(x: Double(i), y: resultArray[i].value))
            label.append(resultArray[i].name)
            colors.append(resultArray[i].color)
        }

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: label)

        if chartView.data == nil {
            // MARK: BarChartDataSet
            let label = "Rubric"
            var dataSet = BarChartDataSet()

            dataSet = BarChartDataSet(entries: entries, label: label)

            dataSet.colors = colors
            dataSet.drawValuesEnabled = true
            dataSet.barBorderWidth = 0.1
            dataSet.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)

            chartView.xAxis.labelCount  = entries.count

            // MARK: BarChartData
            let data = BarChartData(dataSets: [dataSet])

            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
            data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
            data.setValueTextColor(NSColor.black)
            chartView.data = data
            
        } else {
            // MARK: BarChartDataSet
            let set1 = chartView.data!.dataSets[0] as! BarChartDataSet
            set1.colors = colors
            set1.replaceEntries( entries )

            // MARK: BarChartData
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
}

struct RangeSlider: View {
    let minValue: Double
    let maxValue: Double

    @Binding var lowerValue: Double
    @Binding var upperValue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knobSize: CGFloat = 20
            let range = maxValue - minValue

            let lowerX = width * CGFloat((lowerValue - minValue) / range)
            let upperX = width * CGFloat((upperValue - minValue) / range)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: upperX - lowerX, height: 4)
                    .offset(x: lowerX)

                // Lower knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(radius: 2)
                    .position(x: lowerX, y: 10)
                    .gesture(DragGesture().onChanged { value in
                        let percent = max(0, min(1, value.location.x / width))
                        lowerValue = min(maxValue, max(minValue, percent * range))
                        if lowerValue > upperValue {
                            lowerValue = upperValue
                        }
                    })

                // Upper knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(radius: 2)
                    .position(x: upperX, y: 10)
                    .gesture(DragGesture().onChanged { value in
                        let percent = max(0, min(1, value.location.x / width))
                        upperValue = min(maxValue, max(minValue, percent * range))
                        if upperValue < lowerValue {
                            upperValue = lowerValue
                        }
                    })
            }
        }
    }
}
