//
//  CSVImportButton.swift
//  CSVEditor
//
//  Created by Karin Prater on 11/11/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine


struct CSVImportButtonCSV: View {
    
    @ObservedObject var viewModel: CSVViewModel
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Importing the CSV file…", systemImage: "square.and.arrow.down")
        }
        .fileImporter(isPresented: $isPresented,
                      allowedContentTypes: [UTType.commaSeparatedText]) { result in
            viewModel.handleFileImport(for: result)
        }
    }
}

struct CSVImportButtonOFX: View {
    
    @ObservedObject var viewModel: CSVViewModel
    @State private var isPresented: Bool = false
    
    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Importing the OFX file…", systemImage: "square.and.arrow.down")
        }
        .fileImporter(isPresented: $isPresented,
                      allowedContentTypes: [.ofx]) { result in
            viewModel.handleFileImport(for: result)
        }
    }
}
