
import SwiftUI
import SwiftData
import DGCharts



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

struct DGBarChartView: NSViewRepresentable {
    let entries: [BarChartDataEntry]

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
}



struct CategorieBar1View1: View {
    var dataEntries: [BarChartDataEntry] = [
        BarChartDataEntry(x: 1.0, y: 500.0),
        BarChartDataEntry(x: 2.0, y: 1000.0),
        BarChartDataEntry(x: 3.0, y: 750.0),
        BarChartDataEntry(x: 4.0, y: 1200.0),
        BarChartDataEntry(x: 5.0, y: 900.0)
    ]

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30

    var body: some View {
        VStack {
            Text("CategorieBar1View1")
                .font(.headline)
                .padding()
            DGBarChartView(entries: dataEntries)
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
    }

    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
