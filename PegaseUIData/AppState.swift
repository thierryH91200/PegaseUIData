//
//  AppState.swift
//  WelcomeTo
//
//  Created by thierryH24 on 10/08/2025.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var databaseURL: URL? = nil
    @Published var isProjectOpen = false
}
