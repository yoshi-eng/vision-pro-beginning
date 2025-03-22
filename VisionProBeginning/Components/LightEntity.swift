//
//  LightEntity.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

class LightEntity {

    static func generateLightEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.1)
        let materials = [SimpleMaterial(color: .yellow, isMetallic: true)]
        let model = ModelEntity(mesh: mesh, materials: materials)
        
        // 自分の正面に配置
        model.position = SIMD3<Float>(0, 1, -4)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }
}
