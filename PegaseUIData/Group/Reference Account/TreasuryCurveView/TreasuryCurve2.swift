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
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    
    @State var lineDataEntries: [ChartDataEntry] = []
    @StateObject private var viewModel = TresuryLineViewModel()
    
    let transactions: [EntityTransaction]
    
    @Binding var allTransactions: [EntityTransaction]
    @State var filteredTransactions: [EntityTransaction] = []
    
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @Binding var minDate: Date
    @Binding var maxDate: Date
    
    private var firstDate: Date {
        transactions.first?.dateOperation ?? Date()
    }
    
    private var lastDate: Date {
        transactions.last?.dateOperation ?? Date()
    }
    
    private var durationDays: Double {
        lastDate.timeIntervalSince(firstDate) / 86400
    }
    
    private var totalAmount: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
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
                .onChange(of: currentAccountManager.currentAccount) { oldAccount, newAccount in
                    if oldAccount != newAccount {
                        viewModel.refresh(for: newAccount, minDate: minDate)
                    }
                }
                
                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Période sélectionnée : \(dateFromOffset(lowerValue)) → \(dateFromOffset(upperValue))")
                        
                        //                        Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        RangeSlider(minValue: .constant(0),
                                    maxValue: .constant(durationDays),
                                    lowerValue: $lowerValue,
                                    upperValue: $upperValue,
                                    referenceDate: minDate ,
                                    transactionCount: filteredTransactions.count
                        )
                        .frame(height: 50)
                        
                        Text("\(selectedDays) jours du \(formattedDate(from: lowerValue)) au \(formattedDate(from: upperValue)) — \(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : ""), solde total : \(formattedAmount(totalAmount))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        List(filteredTransactions, id: \.uuid) { transaction in
                            Text(transaction.sousOperations.first?.libelle ?? "N/A")
                        }
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
            }
            .onAppear {
                
                allTransactions = ListTransactionsManager.shared.getAllData().sorted { $0.dateOperation < $1.dateOperation }
                
                guard let first = allTransactions.first?.dateOperation,
                      let last = allTransactions.last?.dateOperation else { return }
                
                minDate = first
                maxDate = last
                
                let totalDays = last.timeIntervalSince(first) / 86400
                lowerValue = 0
                upperValue = totalDays
                
                applyFilter()
                
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
            .onChange(of: lowerValue) { _, newStart in
                applyFilter()
            }
            .onChange(of: selectedEnd) { _, newEnd in
                applyFilter()
            }
            .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
                if newAccount != nil {
                    // Recharger les données pour le nouveau compte
                    viewModel.updateAccount(minDate: minDate)
                    viewModel.dataGraph.removeAll()
                    viewModel.dataEntries.removeAll()
                }
            }
        }
    }
    
    
    func dateFromOffset(_ offset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(offset), to: minDate) ?? minDate
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    func applyFilter() {
        guard !allTransactions.isEmpty else {
            filteredTransactions = []
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: Int(lowerValue), to: minDate) ?? minDate
        let endDate = Calendar.current.date(byAdding: .day, value: Int(upperValue), to: minDate) ?? maxDate
        
        filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }
    }
    private var selectedDays: Int {
        max(Int(upperValue - lowerValue) + 1, 1)
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
    
    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
