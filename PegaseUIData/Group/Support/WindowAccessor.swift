//
//  WindowAccessor.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import SwiftUI
import Combine

//
//  WindowAccessor.swift
//  Welcome
//
//  Created by thierryH24 on 04/08/2025.
//

import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

//private class ObservingView: NSView {
//    var windowChanged: ((NSWindow?) -> Void)?
//    private var observation: NSKeyValueObservation?
//    private var lastWindow: NSWindow?
//
//    override func viewDidMoveToWindow() {
//        super.viewDidMoveToWindow()
//        observeWindow()
//    }
//    
//    private func observeWindow() {
//        observation?.invalidate()
//        observation = observe(\ObservingView.window, options: [.initial, .new]) { [weak self] view, change in
//            guard let self = self else { return }
//            if self.window !== self.lastWindow {
//                self.lastWindow = self.window
//                self.windowChanged?(self.window)
//            }
//        }
//    }
//    
//    deinit {
//        observation?.invalidate()
//    }
//}
