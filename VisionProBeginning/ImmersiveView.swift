//
//  ImmersiveView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @State var route = 9
    
    var body: some View {
        Group {
            switch route {
            case 0: LookBackView()
            case 1: DarkView {
                route = 2
            }
            case 9:
                // デバッグ用
                RealityView { content in
                    content.add(BackSphereEntity.shared)
                }
            default: ComeBackView()
            }
        }
        .gesture(TapGesture().targetedToEntity(BackSphereEntity.shared).onEnded { _ in
            Task { @MainActor in
                // イマーシブを終了する
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
                
                // ウインドウを表示する
                openWindow(id: appModel.windowGroupID)
            }
        })
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
