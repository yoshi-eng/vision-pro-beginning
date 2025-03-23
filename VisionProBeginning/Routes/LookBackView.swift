//
//  LookBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

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
    
    // 破裂音の再生用プレイヤーを保持する配列
    @State private var audioPlayers: [AVAudioPlayer] = []
    
    // RealityViewのコンテンツを保持するプロパティ
    @State private var currentContent: RealityViewContent?
    
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
    
    // バブルが弾ける効果を生成する
    private func createBubblePopEffect(at position: SIMD3<Float>, in content: RealityViewContent) {
        // 小さなパーティクルを作成
        for _ in 0..<10 {
            let particleSize: Float = Float.random(in: 0.01...0.05)
            let particleMesh = MeshResource.generateSphere(radius: particleSize)
            
            var material = PhysicallyBasedMaterial()
            material.blending = .transparent(opacity: .init(floatLiteral: 0.5))
            material.clearcoat = .init(floatLiteral: 1.0)
            
            let particle = ModelEntity(mesh: particleMesh, materials: [material])
            
            // ランダムな方向に飛び散る位置を計算
            let randomOffset = SIMD3<Float>(
                Float.random(in: -0.3...0.3),
                Float.random(in: -0.3...0.3),
                Float.random(in: -0.3...0.3)
            )
            particle.position = position + randomOffset
            
            content.add(particle)
            
            // ランダムな方向に飛び散る
            let targetPosition = position + randomOffset * 2
            
            // アニメーション
            let duration: TimeInterval = 0.5
            
            // Transform.scaleを使用して縮小アニメーションを作成
            var finalTransform = particle.transform
            finalTransform.translation = targetPosition
            finalTransform.scale = SIMD3<Float>(0.01, 0.01, 0.01)
            
            // 適切なアニメーションを適用
            particle.move(to: finalTransform, relativeTo: nil, duration: duration, timingFunction: .easeIn)
            
            // アニメーション終了後に削除
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                particle.removeFromParent()
            }
        }
    }
    
    // 破裂音を再生
    private func playPopSound() {
        print("playPopSound called")
        
        // まずはバブル破裂音を試す
        if let soundURL = Bundle.main.url(forResource: "bubble_pop", withExtension: "wav") {
            playSound(url: soundURL)
            return
        }
        
        print("No sound files found")
    }
    
    // 実際に音を再生するメソッド
    private func playSound(url: URL) {
        do {
            // 新しいプレイヤーを作成
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.prepareToPlay()
            
            // プレイヤーを配列に保持
            audioPlayers.append(player)
            
            // 再生開始
            let success = player.play()
            print("Play sound result: \(success)")
            
            // 再生が終わったら配列から削除
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                if let index = self.audioPlayers.firstIndex(of: player) {
                    self.audioPlayers.remove(at: index)
                    print("Removed player from array, count: \(self.audioPlayers.count)")
                }
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }

    var body: some View {
        RealityView { content in
            // RealityViewのコンテンツを保存
            self.currentContent = content
            
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
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleBubbleTap(value.entity)
                }
        )
        .gesture(TapGesture().targetedToEntity(LookBackView.breakBubbleEntity).onEnded { _ in
            print("\(remainBubbleEntities.count)/\(allBubbleEntities.count)")
            // バブルを一つ消したということにする
            if remainBubbleEntities.count > 1 {
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
    
    // バブルタップ時の処理
    private func handleBubbleTap(_ entity: Entity?) {
        print("handleBubbleTap called with entity: \(String(describing: entity))")
        
        // タップされたエンティティか親がVideoPlayerEntityかどうか確認
        guard let tappedEntity = entity else { return }
        
        // タップされたエンティティから対応するVideoPlayerEntityを探す
        var videoEntityToRemove: VideoPlayerEntity? = nil
        
        // 子階層をチェック - バブルをタップした場合
        if let parent = tappedEntity.parent,
           let videoEntity = remainBubbleEntities.first(where: { $0.entity == parent }) {
            videoEntityToRemove = videoEntity
        }
        
        // 直接チェック - ビデオエンティティをタップした場合
        if videoEntityToRemove == nil,
           let videoEntity = remainBubbleEntities.first(where: { $0.entity == tappedEntity }) {
            videoEntityToRemove = videoEntity
        }
        
        if let videoEntity = videoEntityToRemove,
           let index = remainBubbleEntities.firstIndex(where: { $0.entity == videoEntity.entity }) {
            
            // パーティクルエフェクトを生成
            if let content = currentContent {
                createBubblePopEffect(at: videoEntity.entity.position, in: content)
            }
            
            // 破裂音を再生
            playPopSound()
            
            // 色の変更
            self.colorCount = "color\(remainBubbleEntities.count)"
            
            // 配列から削除
            remainBubbleEntities.remove(at: index)
            
            // 最後のバブルを消したら次へ
            if remainBubbleEntities.isEmpty {
                // 全てのビデオを停止する
                for videoEntity in allBubbleEntities {
                    videoEntity.player.pause()
                }
                
                // 次へ進む
                onBrokenAllBubbles()
            }
        }
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
            return Color(red: 0.05, green: 0.01, blue: 0.01)
        case .color4:
            print("printing color4")
            return Color(red: 0.09, green: 0.07, blue: 0.07)
        case .color5:
            print("printing color5")
            return .white
        }
    }
}
