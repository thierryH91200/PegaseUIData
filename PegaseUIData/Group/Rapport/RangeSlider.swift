//
//  RangeSlider.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


import SwiftUI

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    
    var referenceDate: Date // correspond à minDate
    
    private var selectedDays: Int {
        max(Int(upperValue - lowerValue) + 1, 1) // Sécurité minimale
    }
    
    let step: Double = 1.0

    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - thumbSize
            // 1. Positions brutes pour les thumbs
            let lowerPos = position(for: lowerValue, in: availableWidth)
            let upperPos = position(for: upperValue, in: availableWidth)

            // 2. Positions “safe” pour les labels (ne dépassent pas)
            let labelLowerPos = min(max(lowerPos, 40), availableWidth - 40)
            let labelUpperPos = min(max(upperPos, 40), availableWidth - 40)

            ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    // 🔷 1. Dates au-dessus des poignées
                    ZStack {
                        Text(dateString(for: lowerValue))
                            .font(.caption2)
                            .position(x: labelLowerPos + thumbSize / 2, y: 10)

                        Text(dateString(for: upperValue))
                            .font(.caption2)
                            .position(x: labelUpperPos + thumbSize / 2, y: 10)
                    }
                    .frame(height: 20)
                    .padding(.horizontal, thumbSize / 2)

                    // 🔷 2. Slider principal avec les poignées
                    ZStack(alignment: .leading) {
                        // Piste grise
                        Capsule()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: trackHeight)
                            .padding(.horizontal, thumbSize / 2)

                        // Piste bleue sélectionnée
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(
                                width: upperPos - lowerPos,
                                height: trackHeight
                            )
                            .padding(.leading, lowerPos + thumbSize / 2)
                            .padding(.trailing, availableWidth - upperPos + thumbSize / 2)

                        // Poignée gauche
                        thumbView
                            .offset(x: lowerPos)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let percent = clampedPercent(from: value.location.x, width: availableWidth)
                                        lowerValue = min(valueFrom(percent: percent), upperValue)
                                    }
                            )

                        // Poignée droite
                        thumbView
                            .offset(x: upperPos)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let percent = clampedPercent(from: value.location.x, width: availableWidth)
                                        upperValue = max(valueFrom(percent: percent), lowerValue)
                                    }
                            )
                    }
                }
                Text("Number of days selected : \(selectedDays)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .frame(height: thumbSize)
    }

    private var thumbView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(radius: 2)
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
            )
    }

    private func position(for value: Double, in width: CGFloat) -> CGFloat {
        guard maxValue > minValue else { return 0 }
        let percent = (value - minValue) / (maxValue - minValue)
        let pos = CGFloat(percent) * width
//        pos = min(pos, width - 40)
        return pos
    }

    private func valueFrom(percent: CGFloat) -> Double {
        let rawValue = minValue + Double(percent) * (maxValue - minValue)
        let steppedValue = (rawValue / step).rounded() * step
        return steppedValue
    }
    
    private func clampedPercent(from x: CGFloat, width: CGFloat) -> CGFloat {
        min(max(0, x - thumbSize / 2), width) / width
    }
    
    private func dateString(for offset: Double) -> String {
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: Int(offset), to: referenceDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return "–"
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

