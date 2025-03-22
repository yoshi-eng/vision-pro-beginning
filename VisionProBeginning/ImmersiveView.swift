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
    
    var body: some View {
        RealityView { content in
            // 画面を戻るマテリアル
            let model = ModelEntity(
                mesh: .generateSphere(radius: 0.1),
                materials: [SimpleMaterial(color: .white, isMetallic: true)])
            
            // 自分の正面の1mの位置に配置
            model.position = SIMD3<Float>(0.0, 0.0, -5.0)
            
            // Enable interactions on the entity.
            model.components.set(InputTargetComponent())
            model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
            content.add(model)
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
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
