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
//    func createVideoEntity(fileName: String) -> Entity {
//        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
//            print("\(fileName).movが見つかりません")
//            fatalError()
//        }
//
//        let asset = AVURLAsset(url: url)
//        let playerItem = AVPlayerItem(asset: asset)
//        let avPlayer1 = AVPlayer(playerItem: playerItem)
//        
//        // 間隔と基準位置（2x2のグリッド）
//        let spacing: Float = 15.0 // より広い間隔に
//        let depth: Float = -20.0  // より遠くに配置
//        let videoInfo = VideoInfo(position:  SIMD3<Float>(-spacing/2, spacing/2, depth))
//
//        // ビデオ情報を更新（位置情報は維持）
//        guard let updatedVideoInfo = await VideoTools.getVideoInfo(asset: asset, existingInfo: videoInfo) else {
//            print("ビデオ情報の取得に失敗しました")
//            return
//        }
//        
//        // ビデオプレーン用のメッシュとトランスフォームを取得
//        guard let (_, baseTransform) = await VideoTools.makeVideoMesh(videoInfo: updatedVideoInfo) else {
//            print("ビデオメッシュの作成に失敗しました")
//            return
//        }
//        
//        // ビデオマテリアルを作成
//        let videoMaterial = VideoMaterial(avPlayer: avPlayer1)
//    }
    var body: some View {
        RealityView { content in
            let avPlayer1 = AVPlayer()
            let avPlayer2 = AVPlayer()
            let rootEntity = AnchorEntity()
            rootEntity.name = "parent"
            
            let fileName = "video1"

            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
                print("\(fileName).movが見つかりません")
                return
            }

            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            
            avPlayer1.replaceCurrentItem(with: playerItem)

            // 間隔と基準位置（2x2のグリッド）
            let spacing: Float = 15.0 // より広い間隔に
            let depth: Float = -20.0  // より遠くに配置
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
            let videoMaterial = VideoMaterial(avPlayer: avPlayer1)
            
            // ステレオモードを設定
            videoMaterial.controller.preferredViewingMode = .stereo
            
            // 円形ポータル用のメッシュを作成
            let portalRadius: Float = 0.4
            let portalMesh = VideoTools.createPortalMesh(radius: portalRadius)
            
            // ビデオ表示用エンティティを作成（円形メッシュを使用）
            let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
            videoEntity.position = SIMD3<Float>(-spacing/2, spacing/2, depth)
            videoEntity.name = "video1"

            // ビデオが正面を向くようにスケールと回転を設定
            videoEntity.transform.scale = baseTransform.scale
            videoEntity.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
//            videoEntity.transform.translation = updatedVideoInfo.position

            let asset2 = AVURLAsset(url: url)
            let playerItem2 = AVPlayerItem(asset: asset2)
            avPlayer2.replaceCurrentItem(with: playerItem2)
//            avPlayer2.play()

            let videoInfo2 = VideoInfo(position:  SIMD3<Float>(spacing/2, spacing/2, depth))
            // ビデオ情報を更新（位置情報は維持）
            guard let updatedVideoInfo2 = await VideoTools.getVideoInfo(asset: asset, existingInfo: videoInfo2) else {
                print("ビデオ情報の取得に失敗しました")
                return
            }
            // ビデオプレーン用のメッシュとトランスフォームを取得
            guard let (_, baseTransform2) = await VideoTools.makeVideoMesh(videoInfo: updatedVideoInfo2) else {
                print("ビデオメッシュの作成に失敗しました")
                return
            }
            
            // ビデオマテリアルを作成
            let videoMaterial2 = VideoMaterial(avPlayer: avPlayer2)
            
            // ステレオモードを設定
            videoMaterial2.controller.preferredViewingMode = .stereo
            
            // ビデオ表示用エンティティを作成（円形メッシュを使用）
            let portalRadius2: Float = 0.4
            let portalMesh2 = VideoTools.createPortalMesh(radius: portalRadius2)
            let videoEntity2 = ModelEntity(mesh: portalMesh2, materials: [videoMaterial2])
            videoEntity2.position = SIMD3<Float>(spacing/2, spacing/2, depth)
            videoEntity2.name = "video2"

            // ビデオが正面を向くようにスケールと回転を設定
            videoEntity2.transform.scale = baseTransform2.scale
            videoEntity2.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
//            videoEntity2.transform.translation = SIMD3<Float>(-spacing/2, spacing/2, depth)// updatedVideoInfo2.position
            
            avPlayer1.play()
            avPlayer2.play()
            content.add(rootEntity)
            rootEntity.addChild(videoEntity)
            rootEntity.addChild(videoEntity2)
        }
    }
}
