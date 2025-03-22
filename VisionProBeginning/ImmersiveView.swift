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
            let fileName = "video1"
                            
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
                print("\(fileName).movが見つかりません")
                return
            }

            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            playerModel.avPlayer.replaceCurrentItem(with: playerItem)
            playerModel.avPlayer.play()

            // 間隔と基準位置（2x2のグリッド）
            let spacing: Float = 15.0 // より広い間隔に
            let depth: Float = -40.0  // より遠くに配置
            let videoInfo = VideoInfo(position:  SIMD3<Float>(-spacing/2, spacing/2, depth))

            // ビデオ情報を更新（位置情報は維持）
            guard let updatedVideoInfo = await VideoTools.getVideoInfo(asset: asset, existingInfo: videoInfo) else {
                print("ビデオ情報の取得に失敗しました")
                return
            }
            
            
            // ビデオプレーン用のメッシュとトランスフォームを取得
            guard let (_, baseTransform) = await VideoTools.makeVideoMesh(videoInfo: updatedVideoInfo) else {
                print("ビデオメッシュの作成に失敗しました")
                return
            }
            
            // ビデオマテリアルを作成
            let videoMaterial = VideoMaterial(avPlayer: playerModel.avPlayer)
            
            // ステレオモードを設定
            videoMaterial.controller.preferredViewingMode = .stereo
            
            // 円形ポータル用のメッシュを作成
            let portalRadius: Float = 0.4
            let portalMesh = VideoTools.createPortalMesh(radius: portalRadius)
            
            // ビデオ表示用エンティティを作成（円形メッシュを使用）
            let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
            
            // ビデオが正面を向くようにスケールと回転を設定
            videoEntity.transform.scale = baseTransform.scale
            videoEntity.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
            videoEntity.transform.translation = updatedVideoInfo.position
            
            rootEntity.addChild(videoEntity)
            
            content.add(rootEntity)
        }
    }
}
