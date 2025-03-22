//
//  VideoPlayerEntity.swift
//  VisionProBeginning
//
//  Created by minoru fujino on 2025/03/22.
//

import SwiftUI
import AVFoundation
import RealityFoundation

/**
 * An entity to play circle-shaped video any place on RealityView
 * This is a wrapper struct of Entity to handle the entity with an AVPlayer
 */
struct VideoPlayerEntity {
    let player: AVPlayer
    let entity: Entity
    
    init(position: SIMD3<Float>, radius: Float, videoName: String) {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov") else {
            print("\(videoName).movが見つかりません")
            fatalError()
        }
        self.player = AVPlayer(url: url)
        player.isMuted = true
        player.play()
        
        let videoMaterial = VideoMaterial(avPlayer: player)
        videoMaterial.controller.preferredViewingMode = .stereo
        
        let portalMesh = MeshResource.generatePlane(width: radius * 2, depth: radius * 2, cornerRadius: radius)
        
        let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
        videoEntity.scale = SIMD3<Float>(1, 1, 1)
        videoEntity.position = position
        videoEntity.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        
        self.entity = videoEntity
    }
}
