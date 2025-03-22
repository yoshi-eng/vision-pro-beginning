//
//  ImmersiveView.swift
//  VisionProBeginning
//
//  Created by Hidenari Tajima on 2025/03/22.
//

import SwiftUI
import RealityKit
import AVFoundation

// MARK: - Immersive Player View
struct ImmersiveView: View {
    @Environment(PlayerModel.self) private var playerModel: PlayerModel
    
    var body: some View {
        RealityView { content in
            let rootEntity = Entity()
            
            // 4つのビデオファイル名を定義
            let videoFileNames = ["video1", "video2", "video3", "video4"]
                            
            // 適切な距離でビデオを配置
            // 地面に対して垂直になるように配置
            let distance: Float = -3.0 // ユーザーからの距離
            let videoPositions = [
                SIMD3<Float>(-2.2, -2.2, distance),     // 左側
                SIMD3<Float>(1.2, 1.2, distance),      // 右側
                SIMD3<Float>(-0.4, -0.4, distance-0.5), // 左手前
                SIMD3<Float>(0.4, 0.4, distance-0.5)   // 右手前
            ]
            
            // 4つのビデオを表示
            for (index, position) in videoPositions.enumerated() {
                // 対応するビデオファイルを取得
                let fileName = videoFileNames[index]
                
                guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
                    print("\(fileName).movが見つかりません")
                    continue
                }
                
                let asset = AVURLAsset(url: url)
                
                // プレーヤーインスタンスを作成
                let player = AVPlayer(url: url)
                
                // 再生開始
                player.play()
                
                let videoInfo = VideoInfo(position: position)
                
                // ビデオ情報を更新
                guard let updatedVideoInfo = await VideoTools.getVideoInfo(asset: asset, existingInfo: videoInfo) else {
                    print("ビデオ情報の取得に失敗しました")
                    continue
                }
                
                // ビデオプレーン用のメッシュとトランスフォームを取得
                guard let (_, baseTransform) = await VideoTools.makeVideoMesh(videoInfo: updatedVideoInfo) else {
                    print("ビデオメッシュの作成に失敗しました")
                    continue
                }
                
                // ビデオマテリアルを作成
                let videoMaterial = VideoMaterial(avPlayer: player)
                
                // ステレオモードで再生
                videoMaterial.controller.preferredViewingMode = .stereo
                
                // 円形ポータル用のメッシュを作成
                let portalRadius: Float = 0.2 // サイズを小さく調整
                let portalMesh = VideoTools.createPortalMesh(radius: portalRadius)
                
                // ビデオ表示用エンティティを作成（円形メッシュを使用）
                let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
                
                // 地面に対して垂直に配置（正面を向くように）
                // 地面に対して垂直に配置するための回転
                let rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
                
                // スケールと位置を設定（サイズを小さく）
                videoEntity.transform.scale = SIMD3<Float>(baseTransform.scale.x * 0.3, baseTransform.scale.y * 0.3, baseTransform.scale.z * 0.3)
                videoEntity.transform.rotation = rotation
                videoEntity.transform.translation = position
                
                rootEntity.addChild(videoEntity)
            }
            
            content.add(rootEntity)
        }
    }
}
