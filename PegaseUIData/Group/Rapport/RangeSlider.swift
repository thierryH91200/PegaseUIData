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
    @Binding var minValue: Double
    @Binding var maxValue: Double

    @Binding var lowerValue: Double
    @Binding var upperValue: Double

    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - thumbSize

            // Position en pixels des poignées
            let lowerThumbPosition = position(for: lowerValue, in: width)
            let upperThumbPosition = position(for: upperValue, in: width)

            ZStack {
                // Piste globale
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)

                // Piste sélectionnée
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: upperThumbPosition - lowerThumbPosition, height: 6)
                    .offset(x: lowerThumbPosition + thumbSize / 2)

                // Poignée gauche
                Circle()
                    .frame(width: thumbSize, height: thumbSize)
                    .foregroundColor(.accentColor)
                    .position(x: lowerThumbPosition + thumbSize / 2, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let percent = min(max(0, value.location.x - thumbSize / 2), width) / width
                                lowerValue = valueFrom(percent: percent)
                                lowerValue = min(lowerValue, upperValue)
                            }
                    )

                // Poignée droite
                Circle()
                    .frame(width: thumbSize, height: thumbSize)
                    .foregroundColor(.accentColor)
                    .position(x: upperThumbPosition + thumbSize / 2, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let percent = min(max(0, value.location.x - thumbSize / 2), width) / width
                                upperValue = valueFrom(percent: percent)
                                upperValue = max(upperValue, lowerValue)
                            }
                    )
            }
        }
        .frame(height: thumbSize * 2)
    }

    private func position(for value: Double, in width: CGFloat) -> CGFloat {
        let percent = (value - minValue) / (maxValue - minValue)
        return CGFloat(percent) * width
    }

    private func valueFrom(percent: CGFloat) -> Double {
        minValue + Double(percent) * (maxValue - minValue)
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

