//
//  RangeSlider.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct RangeSlider: View {
    var minValue: Double
    var maxValue: Double

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

struct SinglePieChartView: NSViewRepresentable {
    let entries: [PieChartDataEntry]
    let title: String

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized: "No chart data available.")
        chartView.usePercentValuesEnabled = true
        chartView.drawHoleEnabled = true
        chartView.holeRadiusPercent = 0.4
        chartView.transparentCircleRadiusPercent = 0.45

        let centerText = NSMutableAttributedString(string: title)
        centerText.setAttributes([
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ], range: NSRange(location: 0, length: centerText.length))
        chartView.centerAttributedText = centerText

        chartView.chartDescription.enabled = false
        chartView.legend.enabled = true
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)

        return chartView
    }

    func updateNSView(_ nsView: PieChartView, context: Context) {
        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = ChartColorTemplates.material() + ChartColorTemplates.pastel()
        dataSet.drawValuesEnabled = true
        dataSet.valueTextColor = .black
        dataSet.entryLabelColor = .black
        dataSet.sliceSpace = 2.0

        let data = PieChartData(dataSet: dataSet)
        let formatter = PieValueFormatter(currencyCode: "EUR")
        data.setValueFormatter(formatter)
        data.setValueFont(.systemFont(ofSize: 11))

        nsView.data = data
        nsView.notifyDataSetChanged()
    }
}

