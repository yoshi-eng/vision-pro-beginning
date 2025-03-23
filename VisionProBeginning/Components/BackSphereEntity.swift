//
//  BackSphereEntity.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

/**
 画面を戻るためのマテリアル
 BackSphereEntity.sharedと呼び出してシングルトンで使用する
 タップすると、イマーシブが終了し、通常のWindowが表示される
 戻る処理はImmersiveViewに定義している
 */
class BackSphereEntity {
    static let shared = {
        // 画面を戻るマテリアル
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .white, isMetallic: true)])
        
        // 自分の正面4m, 下4mの位置に配置
        model.position = SIMD3<Float>(0.0, -4.0, -4.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
}
