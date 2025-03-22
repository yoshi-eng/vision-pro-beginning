//
//  ContentView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        ContentSelectView()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
