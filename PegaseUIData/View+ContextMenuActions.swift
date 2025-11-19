//
//  View+ContextMenuActions.swift
//  PegaseUIData
//
//  Created by thierryH24 on 15/11/2025.
//

import SwiftUI

private struct OnDeleteKey: EnvironmentKey {
    static var defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {

    var onDelete: (() -> Void)? {
        get { self[OnDeleteKey.self] }
        set { self[OnDeleteKey.self] = newValue }
    }
}

extension View {

    func onDelete(_ action: @escaping () -> Void) -> some View {
        environment(\.onDelete, action)
    }
}
