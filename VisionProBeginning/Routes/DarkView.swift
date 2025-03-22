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
    @Environment(AppModel.self) private var appModel
    @State var bubbles: [String] = [] // 仮でString
    @State var isTurnedBack = false
    
    @StateObject var vm: DarkViewModel = DarkViewModel()
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    @State var initialDirection: simd_float2?
    
    var onCatchLight: () -> Void
    
    // 光をつかんだということにするエンティティ
    static let comeBackLight = {
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
        
        // 自分の正面の1mの位置に配置
        model.position = SIMD3<Float>(0.0, 1.0, -5.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    
    var body: some View {
        RealityView { content in
            content.add(BackSphereEntity.shared)
            
            // TODO: bubblesのエンティティを表示する
            
            // TODO: isTurnedBack == true → 光を新たに表示する
            content.add(DarkView.comeBackLight)
            
        } update: { content in
            if let model = content.entities.first(where: { $0 == DarkView.comeBackLight }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [1.0, 1.0, 1.0] : [0.01, 0.01, 0.01]
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

