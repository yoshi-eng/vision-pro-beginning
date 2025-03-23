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
    let bgmEntity = AmbientSoundEntity(audioName: "bgm_main.wav")

    var body: some View {
        RealityView { content in
            // BGMを再生するエンティティ
            content.add(bgmEntity.entity)
            bgmEntity.audioPlaybackController.play()
            
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
        .applySurroundings(color: colorCount)
        .gesture(TapGesture().targetedToEntity(LookBackView.breakBubbleEntity).onEnded { _ in
            print("\(remainBubbleEntities.count)/\(allBubbleEntities.count)")
            // バブルを一つ消したということにする
            if remainBubbleEntities.count > 1 {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {  // Add delay before changing color
//                           self.colorCount = "color\(remainBubbleEntities.count)"
//                       }
                self.colorCount = "color\(remainBubbleEntities.count)"
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

extension View {
    func applySurroundings(color: String) -> some View {
        // Safely unwrap the color
        guard let changedColor = ColorOpacity(rawValue: color) else { return self }

        // Apply the animation only for specific colors, else just apply the surroundings effect
        return self
            .animation(changedColor == .color2 || changedColor == .color3 ? .easeInOut(duration: 0.9) : nil, value: changedColor.color)
            .preferredSurroundingsEffect(.colorMultiply(changedColor.color))
    }
}

enum ColorOpacity: String, CaseIterable {
    case color1, color2, color3, color4, color5

    var color: Color {
        switch self {
        case .color1:
            return .clear
        case .color2:
            print("printing color2")
            return Color(red: 0.01, green: 0.01, blue: 0.01)
        case .color3:
            print("printing color3")
            return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .color4:
            print("printing color4")
            return Color(red: 0.09, green: 0.09, blue: 0.09)
        case .color5:
            print("printing color5")
            return .white
        }
    }
}
