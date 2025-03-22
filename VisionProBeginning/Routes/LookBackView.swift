//
//  LookBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct BubbleModel: Equatable {
    var videoName: String
    var position: SIMD3<Float>
    var radius: Float
    
    init(_ videoName: String, _ position: SIMD3<Float>, _ radius: Float) {
        self.videoName = videoName
        self.position = position
        self.radius = radius
    }
}

struct LookBackView: View {
    // Configuration to display bubbles: fixed value
    var bubbles: [BubbleModel] = [
        BubbleModel("video1", [-1, 1.6, -2], 0.8),
        BubbleModel("video2", [ 1, 1.6, -3], 0.8),
        BubbleModel("video3", [-1, 1.6, -4], 0.8),
        BubbleModel("video4", [ 1, 1.6, -6], 0.8),
    ]
    
    // State of remaining display
    @State var allBubbleEntities: [Entity] = []
    @State var remainBubbleEntities: [Entity] = []
    
    // 最後の一個を消したら次へ
    var onBrokenAllBubbles: () -> Void
    
    // バブルを一つ消したということにするエンティティ
    static let breakBubbleEntity = {
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        
        // 自分の正面の4mの位置に配置
        model.position = SIMD3<Float>(0.0, -1.0, -4.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    let bgmEntity = AmbientSoundEntity(audioName: "bgm_main.wav")

    var body: some View {
        RealityView { content in
            // BGMを再生するエンティティ
            content.add(bgmEntity.entity)
            bgmEntity.audioPlaybackController.play()
            
            // バブルを一つ消したということにするエンティティ
            content.add(LookBackView.breakBubbleEntity)
            
            // バブルを表示
            allBubbleEntities = []
            remainBubbleEntities = []
            for bubble in bubbles {
                let videoEntity = VideoPlayerEntity(position: bubble.position, radius: bubble.radius, videoName: bubble.videoName)
                let bubbleEntity = BubbleEntity.generateBubbleEntity(position: .zero, radius: bubble.radius)
                videoEntity.entity.addChild(bubbleEntity)
                content.add(videoEntity.entity)
                allBubbleEntities.append(videoEntity.entity)
                remainBubbleEntities.append(videoEntity.entity)
            }
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
        } update: { content in
            // 消されたバブルを非表示にする
            for entity in allBubbleEntities {
                if !remainBubbleEntities.contains(where: { $0 == entity }) {
                    if let target = content.entities.first(where: { $0 == entity }) {
                        target.transform.scale = SIMD3<Float>(0.0, 0.0, 0.0)
                    }
                }
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(Color.green))
        .gesture(TapGesture().targetedToEntity(LookBackView.breakBubbleEntity).onEnded { _ in
            // バブルを一つ消したということにする
            if remainBubbleEntities.count > 1 {
                remainBubbleEntities.removeLast()
            } else {
                // 最後の一個を消したら次へ
                onBrokenAllBubbles()
            }
        })
    }
}
