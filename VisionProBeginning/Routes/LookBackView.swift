//
//  LookBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LookBackView: View {
    // バブルの状態管理
    var bubbles: [ModelEntity] = [
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 1.6, -4+2), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 1.6, -4+1), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 1.6, -4+0), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 1.6, -4-2), radius: 0.3)
    ]
    @State var remainBubbles: [ModelEntity] = []
    
    // 最後の一個を消したら次へ
    var onBrokenAllBubbles: () -> Void
    
    // バブルを一つ消したということにするエンティティ
    static let breakBubbleEntity = {
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        
        // 自分の正面の1mの位置に配置
        model.position = SIMD3<Float>(0.0, -1.0, -5.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    
    var body: some View {
        let opacity: Double = (Double(bubbles.count - remainBubbles.count) / Double(bubbles.count)) * 0.5
        RealityView { content in
            // BGM1を再生する
            let rootEntity = AnchorEntity()
            content.add(rootEntity)
            let audioName = "bgm_main.wav"
            /// The configuration to loop the audio file continously.
            let configuration = AudioFileResource.Configuration(shouldLoop: true)
//            rootEntity.addChild(<#T##Entity#>)

            // Load the audio source and set its configuration.
            guard let audio = try? AudioFileResource.load(
                named: audioName,
                configuration: configuration
            ) else {
                print("Failed to load audio file.")
                return
            }
            /// The focus for the directivity of the spatial audio.
            let focus: Double = 0.5
            rootEntity.spatialAudio = SpatialAudioComponent(directivity: .beam(focus: focus))
            // Set the entity to play audio.
            rootEntity.playAudio(audio)

            // バブルを一つ消したということにするエンティティ
            content.add(LookBackView.breakBubbleEntity)
            
            // バブルを表示
            for bubble in bubbles {
                content.add(bubble)
            }
            remainBubbles = bubbles
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
        } update: { content in
            // 消されたバブルを非表示にする
            for bubble in bubbles {
                if !remainBubbles.contains(bubble) {
                    if let model = content.entities.first(where: { $0 == bubble }) {
                        model.transform.scale = SIMD3<Float>(0.0, 0.0, 0.0)
                    }
                }
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(Color.green.opacity(opacity)))
        .gesture(TapGesture().targetedToEntity(LookBackView.breakBubbleEntity).onEnded { _ in
            // バブルを一つ消したということにする
            if remainBubbles.count > 1 {
                remainBubbles.removeLast()
            } else {
                // 最後の一個を消したら次へ
                onBrokenAllBubbles()
            }
        })
    }
}
