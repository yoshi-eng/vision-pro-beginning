//
//  VisionProBeginningApp.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI

@main
struct VisionProBeginningApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup(id: appModel.windowGroupID) {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
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
