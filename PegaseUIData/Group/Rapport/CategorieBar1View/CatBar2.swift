//
//  CatBar3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct CategorieBar1View1: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @StateObject private var viewModel = CategorieBar1ViewModel()
    
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
    
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    private let oneDay = 3600.0 * 24.0 // one day
    
    @State private var chartView: BarChartView?
    
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
                DisclosureGroup("Visible categories") {
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
            Button("Export to PNG") {
                exportChartAsImage()
            }
            .padding(.bottom, 8)
            
            DGBarChart1Representable(viewModel: viewModel,
                                     entries: viewModel.dataEntries)
            .frame(width: 600, height: 400)
            .padding()
            .onAppear {
                viewModel.updateAccount(minDate: minDate)
            }

            

            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        minValue: .constant(0),
                        maxValue: .constant(durationDays),
                        lowerValue: $lowerValue,
                        upperValue: $upperValue,
                        referenceDate: minDate,
                        transactionCount: filteredTransactions.count
                    )
                        .frame(height: 50)
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
            .padding()
            Spacer()
        }
        .onAppear {
            
            DataContext.shared.context = modelContext
            let listTransactions = ListTransactionsManager.shared.getAllData()
            minDate = listTransactions.first!.dateOperation
            maxDate = listTransactions.last!.dateOperation
            selectedEnd = maxDate.timeIntervalSince(minDate) / oneDay

            chartView = BarChartView()
            if let chartView = chartView {
                CategorieBar1ViewModel.shared.configure(with: chartView)
            }
            updateChart()
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


    private func updateChart() {
//        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
//        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!

        DataContext.shared.context = modelContext

//        let currentAccount = CurrentAccountManager.shared.getAccount()!
//        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func exportChartAsImage() {
        guard let chartView = chartView else { return }

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

}
