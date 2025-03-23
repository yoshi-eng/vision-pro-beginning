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
        BubbleModel("video1_image.jpg", [-2, 1.6, 4], 0.6),
        BubbleModel("video2_image.jpg", [ 1, 1.6, 3], 0.6),
        BubbleModel("video3_image.jpg", [-1, 2.2, 3], 0.6),
        BubbleModel("video4_image.jpg", [ 2, 2.2, 4], 0.6)
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
        
        // 発光するマテリアルに変更
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .white)
        material.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .white)
        material.emissiveIntensity = 20.0 // 発光強度を追加
        
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        
        // テキストにも光源を追加
        let textLight = PointLightComponent(
            color: .white,
            intensity: 50000,
            attenuationRadius: 5.0
        )
        textModel.components.set(textLight)
        
        return textModel
    }
    
    // 前に振り向きなおした後のテキスト
    func getTextEntity2() async throws -> ModelEntity {
        let textString = AttributedString("さあ、未来の光を掴み取ろう")
        let textMesh = try await MeshResource(extruding: textString)
        
        // 発光するマテリアルに変更
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .white)
        material.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .white)
        material.emissiveIntensity = 20.0 // 発光強度を追加
        
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        
        // テキストにも光源を追加
        let textLight = PointLightComponent(
            color: .white,
            intensity: 50000,
            attenuationRadius: 5.0
        )
        textModel.components.set(textLight)
        
        return textModel
    }
    
    // 光をつかんだということにするエンティティ
    let lightEntity = {
        // スポットライトのベースとなる球体
        let baseMesh = MeshResource.generateSphere(radius: 0.15)
        // 発光する素材に変更
        var baseMaterial = PhysicallyBasedMaterial()
        baseMaterial.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .yellow)
        baseMaterial.emissiveColor = PhysicallyBasedMaterial.EmissiveColor(color: .yellow)
        baseMaterial.emissiveIntensity = 200.0 // 発光強度をさらに強化
        let baseModel = ModelEntity(mesh: baseMesh, materials: [baseMaterial])
        
        // 自分の正面に配置
        baseModel.position = SIMD3<Float>(0, 1, -4)
        
        // ライトを追加してより明るく
        let pointLight = PointLightComponent(
            color: .yellow,
            intensity: 600000, // さらに強い光
            attenuationRadius: 15.0 // さらに広範囲
        )
        baseModel.components.set(pointLight)
        
        // 実際のスポットライトも追加
        let spotLight = SpotLightComponent(
            color: .yellow,
            intensity: 1000000, // さらに強い光
            innerAngleInDegrees: 30,
            outerAngleInDegrees: 70,
            attenuationRadius: 20
        )
        baseModel.components.set(spotLight)
        
        // Enable interactions on the entity.
        baseModel.components.set(InputTargetComponent())
        baseModel.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.3)]))
        
        // オンロード時に明滅するアニメーションを開始する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // アニメーションタイマー
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                // 現在の光の強度を取得
                if var pointLight = baseModel.components[PointLightComponent.self],
                   var spotLight = baseModel.components[SpotLightComponent.self] {
                    // 光の強度を増減する
                    if pointLight.intensity > 600000 {
                        pointLight.intensity = 600000
                        spotLight.intensity = 1000000
                    } else {
                        pointLight.intensity = 1000000
                        spotLight.intensity = 1500000
                    }
                    // 更新した光のコンポーネントを設定
                    baseModel.components.set(pointLight)
                    baseModel.components.set(spotLight)
                }
            }
        }
        
        return baseModel
    }()
    
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
                let imageEntity = await ImagePlaneEntity.generateImagePlaneEntity(position: bubble.position, radius: bubble.radius, imageName: bubble.videoName, reversed: true)
                let bubbleEntity = BubbleEntity.generateBubbleEntity(position: .zero, radius: bubble.radius)
                imageEntity.addChild(bubbleEntity)
                content.add(imageEntity)
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
