//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI

struct ListTransactions: View {

    @Binding var isVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            SummaryView(executed: 100, planned: 123.10, engaged: 45.5)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .task {
                    await performTrueTask()
                }
            OutlineViewWithColumnsDemo()
                .frame(minWidth: 200, minHeight: 300)
            Spacer()
        }
    }
    private func performTrueTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
    }
}

struct GradientText: View {
    var text: String
    var gradientImage: NSImage? {
        NSImage(named: NSImage.Name("Gradient"))
    }
    
    var body: some View {
        Text(text)
            .font(.custom("Silom", size: 16))
            .background(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
    }
}

struct SummaryView: View {
    var executed: Double
    var planned: Double
    var engaged: Double

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("Executed")
                Text(String(format: "%.2f €", executed))
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

            VStack {
                Text("Planned")
                Text(String(format: "%.2f €", planned))
                    .font(.title)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)

            VStack {
                Text("Engaged")
                Text(String(format: "%.2f €", engaged))
                    .font(.title)
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.1), Color.cyan.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .border(Color.black, width: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: 150)
    }
}


