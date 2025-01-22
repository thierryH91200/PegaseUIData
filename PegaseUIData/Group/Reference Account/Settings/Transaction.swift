//
//  File.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 10/11/2024.
//

import SwiftUI


struct TransactionView: View {
        
    var body: some View {
        DefaultTransactionValuesView()
    }
}

struct DefaultTransactionValuesView: View {
    @State private var selectedStatus: String = "Engaged"
    @State private var selectedRubric: String = "Alimentation"
    @State private var selectedMode: String = "Bank Card"
    @State private var selectedCategory: String = "Alimentation"
    
    let statusOptions = ["Engaged", "Pending", "Completed"]
    let rubricOptions = ["Alimentation", "Transport", "Loisirs"]
    let modeOptions = ["Bank Card", "Cash", "Transfer"]
    let categoryOptions = ["Alimentation", "Loisirs", "Autres"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Default values ​​for transactions for this account.")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("Statut")
                    Picker("Statut", selection: $selectedStatus) {
                        ForEach(statusOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("Mode")
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(modeOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Rubric")
                    Picker("Rubric", selection: $selectedRubric) {
                        ForEach(rubricOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("Category")
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoryOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            HStack {
                Spacer()
                Text("Default sign")
                Rectangle()
//                    .fill(Color.red)
                    .frame(width: 30, height: 5)
                Spacer()
            }
            .padding(.bottom)
        }
        .padding()
//        .background(Color.gray)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

