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
        let meshShape = MeshResource.generateSphere(radius: radius)

        var material = PhysicallyBasedMaterial()
        // Make the bubble as transparent as possible
        material.blending = .transparent(opacity: .init(floatLiteral: 0.1))
        // Add the bubble light effect
        material.clearcoat = .init(floatLiteral: 1.0)
        
        let model = ModelEntity(mesh: meshShape, materials: [material])
        model.position = position
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: radius)]))
        return model
    }
}
