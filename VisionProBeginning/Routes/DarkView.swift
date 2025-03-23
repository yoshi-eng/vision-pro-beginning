//
//  DarkView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct DarkView: View {
    // Configuration to display bubbles: fixed value
    var bubbles: [BubbleModel] = [
        BubbleModel("video1", [-2, 1.6, 4], 0.6),
        BubbleModel("video2", [ 1, 1.6, 3], 0.6),
        BubbleModel("video3", [-1, 2.2, 3], 0.6),
        BubbleModel("video4", [ 2, 2.2, 4], 0.6)
    ]
    
    // 監視系の同期タイマー
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // 振り向いたかどうかを監視する
    @StateObject var worldTracker: WorldTrackingViewModel = WorldTrackingViewModel()
    @State var initialDirection: simd_float2?
    @State var isTurnedBack = false
    @State var textEntity1: ModelEntity?
    @State var textEntity2: ModelEntity?
    
    // 手を伸ばしたかどうかを監視する
    @StateObject var handTracker = HandTrackingViewModel.shared
    
    // 光をつかんだら次へ
    var onCatchLight: () -> Void
    
    // 後ろに振り向かせるための誘導テキスト
    func getTextEntity1() async throws -> ModelEntity {
        let textString = AttributedString("後ろを振り返ってみて")
        let textMesh = try await MeshResource(extruding: textString)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        return textModel
    }
    
    // 前に振り向きなおした後のテキスト
    func getTextEntity2() async throws -> ModelEntity {
        let textString = AttributedString("さあ、未来の光を掴み取ろう")
        let textMesh = try await MeshResource(extruding: textString)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        return textModel
    }
    
    // 光をつかんだということにするエンティティ
    let lightEntity = LightEntity.generateLightEntity()
    
    var body: some View {
        RealityView { content in
            var textModel1: ModelEntity? = nil
            var textModel2: ModelEntity? = nil
            do {
                // 後ろに振り向かせるための誘導テキスト
                textModel1 = try await getTextEntity1()
                if let textModel1 {
                    content.add(textModel1)
                }
                
                // 前に振り向きなおした後のテキスト
                textModel2 = try await getTextEntity2()
                if let textModel2 {
                    textModel2.transform.scale = [0,0,0]
                    content.add(textModel2)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            // do-catchの外でキャッシュするように
            self.textEntity1 = textModel1
            self.textEntity2 = textModel2
            
            // バブルのエンティティを表裏反転して表示
            for bubble in bubbles {
                // TODO: なぜかクラッシュする！！
//                let videoEntity = VideoPlayerEntity(position: bubble.position, radius: bubble.radius, videoName: bubble.videoName)
//                let bubbleEntity = BubbleEntity.generateBubbleEntity(position: .zero, radius: bubble.radius)
//                videoEntity.entity.addChild(bubbleEntity)
//                content.add(videoEntity.entity)
                
                // デバッグ用回避
                let bubbleEntity = BubbleEntity.generateBubbleEntity(position: bubble.position, radius: bubble.radius)
                content.add(bubbleEntity)
            }
            
            // 光をつかんだということにするエンティティ
            content.add(lightEntity)
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
            
        } update: { content in
            // 一度振り向いたら光のエンティティを表示する
            if let model = content.entities.first(where: { $0 == lightEntity }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [1, 1, 1] : [0, 0, 0]
            }
            
            // then 最初のテキストを消して
            if let textEntity1, let model = content.entities.first(where: { $0 == textEntity1 }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [0, 0, 0] : [1, 1, 1]
            }
            
            // then 次のテキストを表示
            if let textEntity2, let model = content.entities.first(where: { $0 == textEntity2 }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [1, 1, 1] : [0, 0, 0]
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(Color(red: 0.0001, green: 0.0001, blue: 0.0001)))
        .gesture(TapGesture().targetedToEntity(lightEntity).onEnded { _ in
            // 光をつかんだということにする
            onCatchLight()
        })
        .task {
            await worldTracker.run()
            // TODO: HandTrackingはシミュレーターだとクラッシュした。
//            await handTracker.run()
        }
        .onReceive(timer) { _ in
            Task {
                // 振り向き具合を取得して判定
                if let transform = await worldTracker.getTransform() {
                    // カメラの変換行列からユーザーの向きを抽出
                    let columns = transform.columns
                    
                    // 前方ベクトルはz軸の負の方向（カメラ座標系の仕様）
                    let forwardVector = simd_float3(-columns.2.x, -columns.2.y, -columns.2.z)
                    
                    // 水平面での方向のみを考慮（y成分を無視）
                    let currentDirection = simd_normalize(simd_float2(forwardVector.x, forwardVector.z))
                    
                    // 初期方向が未設定の場合、現在の方向を初期方向として設定
                    if initialDirection == nil {
                        initialDirection = currentDirection
                        isTurnedBack = false
                    } else if let initialDir = initialDirection {
                        // 初期方向と現在の方向の内積を計算
                        // 内積が負の値なら、2つのベクトルの角度は90度以上（最大180度）
                        let dotProduct = simd_dot(initialDir, currentDirection)
                        
                        // 内積が-0.7未満（約135度以上回転）なら逆を向いたと判定
                        // → -0.5にしたので必要に応じて調整
                        if dotProduct < -0.5 {
                            isTurnedBack = true
                        }
                    }
                }
                
                // TODO: 手を伸ばしたかどうかを取得して判定
                let isReachedHand = false
                if isReachedHand {
                    onCatchLight()
                }
            }
        }
    }
}
