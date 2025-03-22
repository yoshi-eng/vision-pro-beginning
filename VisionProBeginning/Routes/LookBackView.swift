//
//  LookBackView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LookBackView: View {
    var body: some View {
        RealityView { content in
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 0.0, -5.0), radius: 0.2))
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 2.0, -5.0), radius: 0.5))
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(2.0, 0, -5.0), radius: 0.8))
            
            let videoEntity = VideoPlayerEntity(position: SIMD3<Float>(2.0, 0, -4.9), radius: 0.8, videoName: "video1")
            content.add(videoEntity.entity)
        }
    }
}
