//
//  VisionProBeginningApp.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI
import os
import AVFoundation

@MainActor @Observable class PlayerModel {
    private(set) var avPlayer: AVPlayer
    
    init() {
        self.avPlayer = AVPlayer()
    }
}

@main
struct VisionProBeginningApp: App {
    
    @State private var appModel = AppModel()
    @State private var playerViewModel = PlayerViewModel()
    @State private var playerModel: PlayerModel = PlayerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: playerViewModel)
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environment(playerModel)
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
