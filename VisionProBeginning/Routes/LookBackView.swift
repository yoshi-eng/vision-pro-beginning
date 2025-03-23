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

struct LookBackView: View {
    // バブルの状態管理
    var bubbles: [ModelEntity] = [
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 1.6, -4+2), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 1.6, -4+1), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 1.6, -4+0), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 1.6, -4-2), radius: 0.3)
    ]
    @State var remainBubbles: [ModelEntity] = []
    
    // 破裂音の再生用プレイヤーを保持する配列
    @State private var audioPlayers: [AVAudioPlayer] = []
    
    // RealityViewのコンテンツを保持するプロパティ
    @State private var currentContent: RealityViewContent?
    
    // 最後の一個を消したら次へ
    var onBrokenAllBubbles: () -> Void
    
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
        let opacity: Double = (Double(bubbles.count - remainBubbles.count) / Double(bubbles.count)) * 0.5
        RealityView { content in
            // RealityViewのコンテンツを保存
            self.currentContent = content
            // 追加のバブルを生成して配置
            let additionalBubbles = [
                BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 0.0, -5.0), radius: 0.2),
                BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 2.0, -5.0), radius: 0.5),
                BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(2.0, 0, -5.0), radius: 0.8)
            ]
            
            for bubble in additionalBubbles {
                content.add(bubble)
            }
            
            let videoEntity = VideoPlayerEntity(position: SIMD3<Float>(2.0, 0, -4.9), radius: 0.8, videoName: "video1")
            content.add(videoEntity.entity)
            
            // BGM1を再生する
            let rootEntity = AnchorEntity()
            content.add(rootEntity)
            let audioName = "bgm_main.wav"
            /// The configuration to loop the audio file continously.
            let configuration = AudioFileResource.Configuration(shouldLoop: true)

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

            // 初期設定は必要ない
            
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
        // 各バブルに対してジェスチャー認識を追加
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                print("Entity tapped: \(String(describing: value.entity))")
                handleBubbleTap(value.entity)
            }
        )
    }
    

    
    // バブルタップ時の処理
    private func handleBubbleTap(_ entity: Entity?) {
        print("handleBubbleTap called with entity: \(String(describing: entity))")
        
        // タップされたエンティティがバブルかどうか確認
        guard let tappedEntity = entity as? ModelEntity else {
            print("Tapped entity is not a ModelEntity")
            return
        }
        
        // バブルの配列とremainBubbles配列の両方をチェック
        let allBubbles = bubbles + remainBubbles
        var foundBubble: ModelEntity? = nil
        
        // エンティティの直接比較
        for bubble in allBubbles {
            if tappedEntity == bubble {
                foundBubble = bubble
                break
            }
        }
        
        // 直接比較で見つからない場合は、位置で近似マッチング
        if foundBubble == nil {
            let tappedPosition = tappedEntity.position
            
            for bubble in allBubbles {
                let distance = simd_distance(tappedPosition, bubble.position)
                if distance < 0.5 { // 距離の閾値
                    foundBubble = bubble
                    break
                }
            }
        }
        
        // バブルが見つかった場合の処理
        if let bubble = foundBubble {
            print("Bubble found! Processing tap.")
            
            // バブル破裂アニメーション
            playBubblePopAnimation(bubble)
            
            // 破裂音を再生
            playPopSound()
            
            // パーティクルエフェクトを生成
            if let content = currentContent {
                createBubblePopEffect(at: bubble.position, in: content)
            }
            
            // バブルを残りリストから削除
            if let index = remainBubbles.firstIndex(where: { $0 == bubble }) {
                remainBubbles.remove(at: index)
                print("Removed bubble from remainBubbles, count: \(remainBubbles.count)")
                
                // 全てのバブルが破裂したら次へ
                if remainBubbles.isEmpty {
                    onBrokenAllBubbles()
                }
            }
        } else {
            // デバッグ用：タップされたがバブルが見つからなかった場合
            print("No matching bubble found for tapped entity")
            
            // デバッグ用：とりあえずタップされたエンティティに対してアニメーションと音を再生
            playBubblePopAnimation(tappedEntity)
            playPopSound()
            
            // パーティクルエフェクトも生成
            if let content = currentContent {
                createBubblePopEffect(at: tappedEntity.position, in: content)
            }
        }
    }
    
    // 毎回新しいプレイヤーで破裂音を再生
    private func playPopSound() {
        print("playPopSound called")
        
        // まずはバブル破裂音を試す
        if let soundURL = Bundle.main.url(forResource: "bubble_pop", withExtension: "wav") {
            playSound(url: soundURL)
            return
        }
        
        // 代替音を試す
        if let alternativeURL = Bundle.main.url(forResource: "bgm_main", withExtension: "wav") {
            print("Using alternative sound: bgm_main.wav")
            playSound(url: alternativeURL)
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
    
    // バブル破裂アニメーション - パーティクルエフェクトのみを使用
    private func playBubblePopAnimation(_ bubble: ModelEntity) {
        print("playBubblePopAnimation called")
        
        // 即座にバブルを非表示にする
        bubble.isEnabled = false
    }
    

}

#Preview(immersionStyle: .full) {
    LookBackView(onBrokenAllBubbles: {})
        .environment(AppModel())
}
