//
//  VisionProBeginningApp.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI
import os

@main
struct VisionProBeginningApp: App {

    @State private var appModel = AppModel()
    @State private var playerViewModel = PlayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: playerViewModel)
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView(viewModel: playerViewModel)
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}

let logger = Logger()
