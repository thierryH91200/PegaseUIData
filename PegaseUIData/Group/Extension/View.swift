//
//  View.swift
//  PegaseUIData
//
//  Created by thierryH24 on 15/08/2025.
//

import SwiftUI


// MARK: - View Extension
extension View {
    func getHostingWindow(completion: @escaping (NSWindow?) -> Void) -> some View {
        background(WindowAccessor(callback: completion))
    }
}
