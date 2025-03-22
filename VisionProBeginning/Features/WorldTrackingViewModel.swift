//
//  WorldTrackingViewModel.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
final class WorldTrackingViewModel: ObservableObject {
    private let session = ARKitSession()
    private let provider = WorldTrackingProvider()

    func run() async {
        do {
            try await session.run([provider])
            await handleAnchorUpdates()
        } catch {
            print("Failed to run session: \(error)")
        }
    }

    private func handleAnchorUpdates() async {
        for await update in provider.anchorUpdates {
            switch update.event {
            case .added, .updated:
                print("Anchor position updated.")
            case .removed:
                print("Anchor position now unknown.")
            }
        }
    }
    
    func getTransform() async -> simd_float4x4? {
        if let anchor = provider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            return anchor.originFromAnchorTransform
        }
        return nil
    }
}
