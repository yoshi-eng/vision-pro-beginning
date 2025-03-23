//
//  LookBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct BubbleModel {
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
    @State var allBubbleEntities: [VideoPlayerEntity] = []
    @State var remainBubbleEntities: [VideoPlayerEntity] = []
    @State private var surroundingsColor: Color = .white
    @State private var colorCount: String = "color5"
    
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

    var body: some View {
        RealityView { content in
            // バブルを一つ消したということにするエンティティ
            content.add(LookBackView.breakBubbleEntity)
            
            // バブルを表示
            var videoEntities: [VideoPlayerEntity] = []
            for bubble in bubbles {
                let videoEntity = VideoPlayerEntity(position: bubble.position, radius: bubble.radius, videoName: bubble.videoName)
                let bubbleEntity = BubbleEntity.generateBubbleEntity(position: .zero, radius: bubble.radius)
                videoEntity.entity.addChild(bubbleEntity)
                content.add(videoEntity.entity)
                videoEntities.append(videoEntity)
            }
            allBubbleEntities = videoEntities
            remainBubbleEntities = videoEntities
            print("\(remainBubbleEntities.count)/\(allBubbleEntities.count)")
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
        } update: { content in
            // 消されたバブルを非表示にする
            print("\(remainBubbleEntities.count)/\(allBubbleEntities.count)")
            for videoEntity in allBubbleEntities {
                if !remainBubbleEntities.contains(where: { $0.entity == videoEntity.entity }) {
                    if let target = content.entities.first(where: { $0 == videoEntity.entity }) {
                        target.transform.scale = SIMD3<Float>(0.0, 0.0, 0.0)
                    }
                }
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(surroundingsColor))
        .gesture(TapGesture().targetedToEntity(LookBackView.breakBubbleEntity).onEnded { _ in
            print("\(remainBubbleEntities.count)/\(allBubbleEntities.count)")
            // バブルを一つ消したということにする
            if remainBubbleEntities.count > 1 {
                self.colorCount = "color\(remainBubbleEntities.count)"
                let changedColor = ColorOpacity(rawValue: self.colorCount)!.color
                self.surroundingsColor = changedColor
                remainBubbleEntities.removeFirst()
            } else {
                // 全てのビデオを停止する
                for videoEntity in allBubbleEntities {
                    videoEntity.player.pause()
                }
                
                // 最後の一個を消したら次へ
                onBrokenAllBubbles()
            }
        })
    }
    
    
}

enum ColorOpacity: String, CaseIterable {
    case color1, color2, color3, color4

    var color: Color {
            switch self {
            case .color1:
                return .clear
            case .color2:
                print("priting color2")
                return Color(red: 0.001, green: 0.01, blue: 0.01)
            case .color3:
                print("priting color3")
                return Color(red: 0.01, green: 0.01, blue: 0.01)
            case .color4:
                print("priting color4")
                return Color(red: 0.07, green: 0.07, blue: 0.07)
            }
        }
}
