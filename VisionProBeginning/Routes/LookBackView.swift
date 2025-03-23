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
    
    let bgmEntity = AmbientSoundEntity(audioName: "bgm_main.wav")
    
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

    var body: some View {
        RealityView { content in
            // RealityViewのコンテンツを保存
            self.currentContent = content
            
            // BGMを再生するエンティティ
            content.add(bgmEntity.entity)
            bgmEntity.audioPlaybackController.play()
            
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
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
        } update: { content in
            // 消されたバブルを非表示にする
            for videoEntity in allBubbleEntities {
                if !remainBubbleEntities.contains(where: { $0.entity == videoEntity.entity }) {
                    if let target = content.entities.first(where: { $0 == videoEntity.entity }) {
                        target.transform.scale = SIMD3<Float>(0.0, 0.0, 0.0)
                    }
                }
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(surroundingsColor))
        // 各バブルに対してジェスチャー認識を追加
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                handleBubbleTap(value.entity)
            }
        )
    }
    
    // バブルタップ時の処理
    private func handleBubbleTap(_ entity: Entity?) {
        guard let tappedEntity = entity else { return }
        
        // タップされたエンティティがバブルか、またはバブルの親（ビデオエンティティ）か確認
        var targetVideoEntity: VideoPlayerEntity? = nil
        
        // バブルの親子関係を確認
        for videoEntity in remainBubbleEntities {
            if tappedEntity == videoEntity.entity || videoEntity.entity.children.contains(where: { $0 == tappedEntity }) {
                targetVideoEntity = videoEntity
                break
            }
        }
        
        // ビデオエンティティが見つかった場合の処理
        if let videoEntity = targetVideoEntity {
            // バブル破裂効果
            if let content = currentContent {
                createBubblePopEffect(at: videoEntity.entity.position, in: content)
            }
            
            // 破裂音を再生
            playPopSound()
            
            // バブルを残りリストから削除
            if let index = remainBubbleEntities.firstIndex(where: { $0.entity == videoEntity.entity }) {
                // ビデオの再生を停止
                videoEntity.player.pause()
                
                // リストから削除
                remainBubbleEntities.remove(at: index)
                
                // 背景色を変更
                updateBackgroundColor()
                
                // 全てのバブルが破裂したら次へ
                if remainBubbleEntities.isEmpty {
                    // 全てのビデオを停止する
                    for entity in allBubbleEntities {
                        entity.player.pause()
                    }
                    
                    onBrokenAllBubbles()
                }
            }
        }
    }
    
    // 背景色を更新する
    private func updateBackgroundColor() {
        let count = remainBubbleEntities.count
        if count >= 1 && count <= 4 {
            self.colorCount = "color\(count)"
            if let changedColor = ColorOpacity(rawValue: self.colorCount)?.color {
                self.surroundingsColor = changedColor
            }
        }
    }
    
    // 毎回新しいプレイヤーで破裂音を再生
    private func playPopSound() {
        // バブル破裂音を試す
        if let soundURL = Bundle.main.url(forResource: "bubble_pop", withExtension: "wav") {
            playSound(url: soundURL)
            return
        }
        
        // 代替音を試す
        if let alternativeURL = Bundle.main.url(forResource: "bgm_main", withExtension: "wav") {
            playSound(url: alternativeURL)
        }
    }
    
    // 実際に音を再生するメソッド
    private func playSound(url: URL) {
        do {
            // 新しいプレイヤーを作成
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.5
            player.prepareToPlay()
            
            // プレイヤーを配列に保持
            audioPlayers.append(player)
            
            // 再生開始
            player.play()
            
            // 再生が終わったら配列から削除
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                if let index = self.audioPlayers.firstIndex(of: player) {
                    self.audioPlayers.remove(at: index)
                }
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
}

enum ColorOpacity: String, CaseIterable {
    case color1, color2, color3, color4

    var color: Color {
            switch self {
            case .color1:
                return .clear
            case .color2:
                return Color(red: 0.001, green: 0.01, blue: 0.01)
            case .color3:
                return Color(red: 0.01, green: 0.01, blue: 0.01)
            case .color4:
                return Color(red: 0.07, green: 0.07, blue: 0.07)
            }
        }
}
