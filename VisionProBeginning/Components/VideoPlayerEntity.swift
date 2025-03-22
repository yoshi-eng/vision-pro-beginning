//
//  VideoPlayerEntity.swift
//  VisionProBeginning
//
//  Created by minoru fujino on 2025/03/22.
//

import SwiftUI
import AVFoundation
import RealityFoundation

class VideoPlayerEntity {
    
    static func generateVideoPlayerEntity(position: SIMD3<Float>, radius: Float, videoName: String) -> Entity {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov") else {
            print("\(videoName).movが見つかりません")
            fatalError()
        }
        
        // プレーヤーインスタンスを作成
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: playerItem)
        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
//        let player = AVPlayer(url: url)
        player.play()
        
        // ビデオマテリアルを作成
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        // ステレオモードで再生
        videoMaterial.controller.preferredViewingMode = .stereo
        
        // 円形ポータル用のメッシュを作成
        let portalMesh = MeshResource.generatePlane(width: radius * 2,
                                               depth: radius * 2,
                                               cornerRadius: radius)
        
        // ビデオ表示用エンティティを作成（円形メッシュを使用）
        let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
        
        // 地面に対して垂直に配置（正面を向くように）
        // 地面に対して垂直に配置するための回転
        let rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        
        // スケールと位置を設定（サイズを小さく）
        videoEntity.transform.scale = SIMD3<Float>(1, 1, 1)
        videoEntity.transform.rotation = rotation
        videoEntity.transform.translation = position
        
        return videoEntity
    }
}
