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

import SwiftUI

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    
    var referenceDate: Date
    var transactionCount: Int // 👈 Ajouté ici

    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 6
    private let overlapOffset: CGFloat = 6 // décalage en cas d'overlap
    
    private var selectedDays: Int {
        max(Int(upperValue - lowerValue) + 1, 1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - thumbSize
            let lowerPos = position(for: lowerValue, in: availableWidth)
            let upperPos = position(for: upperValue, in: availableWidth)
            
            let overlap = abs(upperPos - lowerPos) < thumbSize

                        ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    // ✅ Affichage des dates
                    ZStack {
                        Text(dateString(for: lowerValue))
                            .font(.caption2)
                            .position(x: lowerPos + thumbSize / 2, y: 10)
                        
                        Text(dateString(for: upperValue))
                            .font(.caption2)
                            .position(x: upperPos + thumbSize / 2, y: 10)
                    }
                    .frame(height: 20)
                    
                    // ✅ Slider
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: trackHeight)
                            .padding(.horizontal, thumbSize / 2)
                        
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: upperPos - lowerPos, height: trackHeight)
                            .padding(.leading, lowerPos + thumbSize / 2)
                            .padding(.trailing, availableWidth - upperPos + thumbSize / 2)
                        
                        // Poignée gauche
                            thumbView(isLeft: true)
                                .offset(x: lowerPos, y: overlap ? 10 : 0)
                                .gesture(
                                    DragGesture().onChanged { value in
                                        let percent = clampedPercent(from: value.location.x, width: availableWidth)
                                        let newValue = round(valueFrom(percent: percent))
                                        if newValue <= upperValue { // ✅ On empêche de dépasser la poignée droite
                                            lowerValue = newValue
                                        }
                                    }
                                )

                            thumbView(isLeft: false)
                            .offset(x: upperPos, y: 0)
                                .gesture(
                                    DragGesture().onChanged { value in
                                        let percent = clampedPercent(from: value.location.x, width: availableWidth)
                                        let newValue = round(valueFrom(percent: percent))
                                        if newValue >= lowerValue { // ✅ On empêche de dépasser la poignée gauche
                                            upperValue = newValue
                                        }
                                    }
                                )
                    }
                }
                
                // ✅ Nombre de jours sélectionnés
                Text("Number of days selected : \(selectedDays)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .frame(height: thumbSize)
    }
        
    // ✅ Calculs
    private func position(for value: Double, in width: CGFloat) -> CGFloat {
        guard maxValue > minValue else { return 0 }
        let percent = (value - minValue) / (maxValue - minValue)
        return CGFloat(percent) * width
    }
    
    private func valueFrom(percent: CGFloat) -> Double {
        minValue + Double(percent) * (maxValue - minValue)
    }
    
    private func clampedPercent(from x: CGFloat, width: CGFloat) -> CGFloat {
        min(max(0, x - thumbSize / 2), width) / width
    }
    
    private func dateString(for value: Double) -> String {
        let daysToAdd = Int(value)
        let date = Calendar.current.date(byAdding: .day, value: daysToAdd, to: referenceDate) ?? referenceDate
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func thumbView(isLeft: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(radius: 2)
                .overlay(
                    Circle().stroke(Color.accentColor, lineWidth: 2)
                )

            Image(systemName: isLeft ? "chevron.right" : "chevron.left")
                .foregroundColor(.accentColor)
                .font(.system(size: thumbSize * 0.5, weight: .bold))
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

