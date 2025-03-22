//
//  ComeBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ComeBackView: View {
    
    func getTextEntity1() async throws -> ModelEntity {
        let textString = AttributedString("おかえりなさい")
        let textMesh = try await MeshResource(
            extruding: textString
        )
        let material = SimpleMaterial(
            color: .black,
            isMetallic: false
        )
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -2)
        
        return textModel
    }
    
    func getTextEntity2() async throws -> ModelEntity {
        let textString = AttributedString("これからもたくさんの思い出を作りましょう")
        let textMesh = try await MeshResource(
            extruding: textString
        )
        let material = SimpleMaterial(
            color: .black,
            isMetallic: false
        )
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 1.5, -2)
        
        return textModel
    }
    
    var body: some View {
        RealityView { content in
            do {
                let textEntity1 = try await getTextEntity1()
                content.add(textEntity1)
                let textEntity2 = try await getTextEntity2()
                content.add(textEntity2)
            } catch {
                print(error.localizedDescription)
            }
            content.add(BackSphereEntity.shared)
        }
    }
}
