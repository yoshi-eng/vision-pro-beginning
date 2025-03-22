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
            let rootEntity = AnchorEntity()
            content.add(rootEntity)
            let audioName = "bgm_main.wav"
            /// The configuration to loop the audio file continously.
            let configuration = AudioFileResource.Configuration(shouldLoop: true)
            rootEntity.addChild(<#T##Entity#>)

            // Load the audio source and set its configuration.
            guard let audio = try? AudioFileResource.load(
                named: audioName,
                configuration: configuration
            ) else {
                print("Failed to load audio file.")
                return
            }
            /// The focus for the directivity of the spatial audio.
            let focus: Double = 0.5
            rootEntity.spatialAudio = SpatialAudioComponent(directivity: .beam(focus: focus))
            // Set the entity to play audio.
            rootEntity.playAudio(audio)
            
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 0.0, -5.0), radius: 0.2))
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(0.0, 2.0, -5.0), radius: 0.5))
            content.add(BubbleEntity.generateBubbleEntity(position: SIMD3<Float>(2.0, 0, -5.0), radius: 0.8))
        }
    }
}
