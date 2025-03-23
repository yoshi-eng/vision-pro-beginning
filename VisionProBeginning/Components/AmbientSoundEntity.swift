//
//  AmbientSoundEntity.swift
//  VisionProBeginning
//
//  Created by Hidenari Tajima on 2025/03/23.
//

import SwiftUI
import AVFoundation
import RealityKit

struct AmbientSoundEntity {
    let audioPlaybackController: AudioPlaybackController
    let entity: Entity
    
    init(audioName: String) {
        entity = AnchorEntity()
        
        /// The configuration to loop the audio file continously.
        let configuration = AudioFileResource.Configuration(shouldLoop: true)
        // Load the audio source and set its configuration.
        guard let audio = try? AudioFileResource.load(
            named: audioName,
            configuration: configuration
        ) else {
            print("Failed to load audio file.")
            fatalError()
        }
        
        /// The focus for the directivity of the spatial audio.
        entity.ambientAudio = AmbientAudioComponent()
        // Set the entity to play audio.
        audioPlaybackController = entity.prepareAudio(audio)
    }
}
