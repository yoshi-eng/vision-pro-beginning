//
//  BubbleEntity.swift
//  VisionProBeginning
//
//  Created by Tiphaine on 2025/03/22.
//
import SwiftUI
import RealityKit
import RealityKitContent

class BubbleEntity {
    
    static func generateBubbleEntity(position: SIMD3<Float>, radius: Float) -> ModelEntity {
        let model = ModelEntity(
            mesh: .generatePlane(width: radius * 2,
                                 depth: radius * 2,
                                 cornerRadius: radius),
            materials: [SimpleMaterial(color: .white, isMetallic: true)]
        )
        
        model.transform.scale = SIMD3<Float>(1, 1, 1)
        model.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        
        model.position = position
        
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }
}
