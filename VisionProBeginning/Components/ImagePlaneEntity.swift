//
//  ImagePlaneEntity.swift
//  VisionProBeginning
//
//  Created by Hidenari Tajima on 2025/03/23.
//

import RealityKit

@MainActor
class ImagePlaneEntity {
    static func generateImagePlaneEntity(position: SIMD3<Float>, radius: Float, imageName: String, reversed: Bool) async -> Entity {
        guard let texture = try? await TextureResource(named: imageName) else {
            fatalError()
        }
        
        let planeMesh = MeshResource.generatePlane(width: radius * 2, depth: radius * 2, cornerRadius: radius)
        
        var imageMaterial = UnlitMaterial()
        imageMaterial.color = PhysicallyBasedMaterial
                                .BaseColor(texture: .init(texture))
        
        let entity = ModelEntity(mesh: planeMesh, materials: [imageMaterial])
        entity.scale = SIMD3<Float>(1, 1, 1)
        entity.position = position
        entity.transform.rotation = reversed ? simd_quatf(from: SIMD3<Float>(0, 1, 0), to: SIMD3<Float>(0, 0, -1)) :  simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))

        return entity
    }
}
