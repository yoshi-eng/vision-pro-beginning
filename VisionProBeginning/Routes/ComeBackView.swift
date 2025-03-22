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
    // テキスト上段
    func getTextEntity1() async throws -> ModelEntity {
        let textString = AttributedString("おかえりなさい")
        let textMesh = try await MeshResource(extruding: textString)
        let material = SimpleMaterial(color: .black, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        return textModel
    }
    
    // テキスト下段
    func getTextEntity2() async throws -> ModelEntity {
        let textString = AttributedString("これからもたくさんの思い出を作りましょう")
        let textMesh = try await MeshResource(extruding: textString)
        let material = SimpleMaterial(color: .black, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 1.6, -4)
        return textModel
    }
    
    let bgmEntity = AmbientSoundEntity(audioName: "bgm_ending.wav")
    
    var body: some View {
        RealityView { content in
            content.add(bgmEntity.entity)
            bgmEntity.audioPlaybackController.play()
            
            // テキストを表示する
            do {
                let textEntity1 = try await getTextEntity1()
                content.add(textEntity1)
                let textEntity2 = try await getTextEntity2()
                content.add(textEntity2)
            } catch {
                print(error.localizedDescription)
            }
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
        }
    }
}
