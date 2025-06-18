//
//  Untitled 3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import AppKit

struct TreasuryCurve: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State var lineDataEntries: [ChartDataEntry] = []
    @StateObject private var viewModel = TresuryLineViewModel()
    
    @State private var minDate = Date()
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    private let oneDay = 3600.0 * 24.0 // one day

    @State private var chartView : LineChartView?
    @State private var rotationAngle: Double = 0
    
    @State var soldeBanque = 0.0
    @State var soldePrevu   = 0.0
    @State var soldeEngage  = 0.0

    @AppStorage("enableSoundFeedback") private var enableSoundFeedback: Bool = true

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Treasury curve")
                    .font(.headline)
                    .padding()
                
                DGLineChartRepresentable(viewModel: viewModel,
                                         entries: viewModel.dataEntries)
                    .frame(width: geometry.size.width, height: 400)
                    .padding()
                    .onAppear {
                        viewModel.updateAccount(minDate: minDate)
                    }

                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        RangeSlider(minValue: minDate.timeIntervalSince(minDate) / (oneDay),
                                    maxValue: maxDate.timeIntervalSince(minDate) / (oneDay),
                                    lowerValue: $selectedStart,
                                    upperValue: $selectedEnd)
                        .frame(height: 30)
                        
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)
                    
                    if selectedStart > 0 || selectedEnd < maxDate.timeIntervalSince(minDate) / oneDay {
                        Toggle(isOn: $enableSoundFeedback) {
                            Label("Sound feedback", systemImage: "speaker.wave.2.fill")
                        }
                        .toggleStyle(.switch)
                        .padding(.top, 8)
                        
                        Button {
                            withAnimation {
                                selectedStart = 0
                                selectedEnd = maxDate.timeIntervalSince(minDate) / oneDay
                            }
                            rotationAngle += 360
                            if enableSoundFeedback {
                                NSSound(named: NSSound.Name("Ping"))?.play()
                            }
                            updateChart()
                        } label: {
                            Label {
                                Text("Reset the range")
                            } icon: {
                                Image(systemName: "arrow.counterclockwise")
                                    .rotationEffect(.degrees(rotationAngle))
                                    .animation(.easeInOut(duration: 0.4), value: rotationAngle)
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                }
                .onAppear {
                    let initAccount = InitAccountManager.shared.getAllData()
                    soldeBanque = initAccount?.realise ?? 0
                    soldeEngage  = initAccount?.engage ?? 0
                    soldePrevu   = initAccount?.prevu ?? 0

                    DataContext.shared.context = modelContext
                    let allTransactions = ListTransactionsManager.shared.getAllData()
                    guard let first = allTransactions.first?.dateOperation,
                          let last = allTransactions.last?.dateOperation else { return }

                    minDate = first
                    maxDate = last
                    selectedEnd = maxDate.timeIntervalSince(minDate) / oneDay

                    chartView = LineChartView()
                    if let chartView = chartView {
                        TresuryLineViewModel.shared.configure(with: chartView)
                        updateChart()
                    }
                }
                .onChange(of: selectedStart) { _, newStart in
                    viewModel.selectedStart = newStart
                    updateChart()
                }
                .onChange(of: selectedEnd) { _, newEnd in
                    viewModel.selectedEnd = newEnd
                    updateChart()
                }
            }
        }
    }
    
    private func updateChart() {
        
        guard let chartView = chartView else { return }
        
        DataContext.shared.context = modelContext

        viewModel.configure(with: chartView)
        viewModel.updateAccount(minDate: minDate) // ← cette ligne est manquante
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
