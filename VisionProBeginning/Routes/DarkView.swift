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
    // バブルは後ろに固定表示
    var bubbles: [ModelEntity] = [
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 2, 4+2), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 2, 4+1), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(-1, 2, 4+0), radius: 0.3),
        BubbleEntity.generateBubbleEntity(position: SIMD3<Float>( 1, 2, 4-2), radius: 0.3)
    ]
    
    // 振り向いたかどうかを監視する
    @StateObject var vm: DarkViewModel = DarkViewModel()
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    @State var initialDirection: simd_float2?
    @State var isTurnedBack = false
    
    // 光をつかんだら次へ
    var onCatchLight: () -> Void
    
    // 後ろに振り向かせるための誘導テキスト
    func getTextEntity() async throws -> ModelEntity {
        let textString = AttributedString("後ろを見て")
        let textMesh = try await MeshResource(extruding: textString)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        let boundingBox = textModel.visualBounds(relativeTo: nil)
        let textWidth = boundingBox.extents.x
        textModel.position = SIMD3<Float>(-textWidth / 2, 2, -4)
        return textModel
    }
    
    // 光をつかんだということにするエンティティ
    static let comeBackLight = {
        let mesh = MeshResource.generateSphere(radius: 0.1)
        let materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
        let model = ModelEntity(mesh: mesh, materials: materials)
        
        // 自分の正面に配置
        model.position = SIMD3<Float>(0, 1, -4)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    
    var body: some View {
        RealityView { content in
            // バブルのエンティティを表裏反転して表示
            for bubble in bubbles {
                bubble.transform.rotation = .init(angle: 180, axis: SIMD3<Float>(1, 0, 0))
                content.add(bubble)
            }
            
            // 光をつかんだということにするエンティティ
            content.add(DarkView.comeBackLight)
            
            // イマーシブを終了するためのエンティティ
            content.add(BackSphereEntity.shared)
            
            // 後ろに振り向かせるための誘導テキスト
            do {
                let textModel = try await getTextEntity()
                content.add(textModel)
            } catch {
                print(error.localizedDescription)
            }
            
        } update: { content in
            // 一度振り向いたら光のエンティティを表示する
            if let model = content.entities.first(where: { $0 == DarkView.comeBackLight }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [1, 1, 1] : [0, 0, 0]
            }
        }
        .preferredSurroundingsEffect(.colorMultiply(.black))
        .gesture(TapGesture().targetedToEntity(DarkView.comeBackLight).onEnded { _ in
            // 光をつかんだということにする
            onCatchLight()
        })
        .task() {
            await vm.run()
        }
        .onReceive(timer) { _ in
            Task {
                if let transform = await vm.getTransform() {
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
            }
        }
    }
}

@MainActor
final class DarkViewModel: ObservableObject {
    let session = ARKitSession()
    let worldInfo = WorldTrackingProvider()

    func run() async {
        do {
            try await session.run([worldInfo])
            await handleAnchorUpdates()
        } catch {
            assertionFailure("Failed to run session: \(error)")
        }
    }

    func handleAnchorUpdates() async {
        for await update in worldInfo.anchorUpdates {
            switch update.event {
            case .added, .updated:
                print("Anchor position updated.")
            case .removed:
                print("Anchor position now unknown.")
            }
        }
    }
    
    func getTransform() async -> simd_float4x4? {
        if let anchor = worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            return anchor.originFromAnchorTransform
        }
        return nil
    }
}

