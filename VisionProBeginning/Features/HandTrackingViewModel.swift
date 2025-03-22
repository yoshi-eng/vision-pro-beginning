//
//  HandTrackingViewModel.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import ARKit

enum HandGesture {
    case notTracked
    case closed
    case custom(Int)
}

enum Hands {
    case left
    case right
}

enum Fingers {
    case thumb
    case index
    case middle
    case ring
    case little
    case wrist
}

enum JointType {
    case tip
    case pip
    case dip
    case mcp
}

@MainActor
class HandTrackingViewModel: ObservableObject {
    static let shared = HandTrackingViewModel()
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()
    
    @Published var leftHandGesture: HandGesture = .notTracked
    @Published var rightHandGesture: HandGesture = .notTracked
    @Published var displayedNumber: Int = 0
    
    private var leftHandAnchor: HandAnchor?
    private var rightHandAnchor: HandAnchor?
    
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
            let handAnchor = update.anchor
            print("handleHandUpdates")
            guard handAnchor.isTracked else {
                continue
            }
            
            if handAnchor.chirality == .left {
                self.leftHandAnchor = handAnchor
                self.leftHandGesture = self.determineHandGesture(hand: .left)
                print("left updated")
            } else {
                self.rightHandAnchor = handAnchor
                self.rightHandGesture = self.determineHandGesture(hand: .right)
                print("right updated")
            }
            self.updateDisplayedNumber()
        }
    }
    
    func determineHandGesture(hand: Hands) -> HandGesture {
        let fingers: [Fingers] = [.thumb, .index, .middle, .ring, .little]
        let extendedFingers = fingers.filter { isStraight(hand: hand, finger: $0) }
        
        if extendedFingers.isEmpty {
            return .closed
        } else {
            return .custom(extendedFingers.count)
        }
    }
    
    private func updateDisplayedNumber() {
        _ = displayedNumber
        displayedNumber = [leftHandGesture, rightHandGesture].reduce(0) { total, gesture in
            switch gesture {
            case .custom(let count):
                return total + count
            default:
                return total
            }
        }
    }
    
    private func extractPosition2D(_ transform: simd_float4x4?) -> CGPoint? {
        guard let transform = transform else { return nil }
        let position = transform.columns.3
        return CGPoint(
            x: CGFloat(position.x),
            y: CGFloat(position.y)
        )
    }
    
    private func isStraight(hand: Hands, finger: Fingers) -> Bool {
        if finger == .thumb {
            return isThumbExtended(hand: hand)
        }
        
        guard let tipPosition = extractPosition2D(jointPosition(hand: hand, finger: finger, joint: .tip)),
              let secondPosition = extractPosition2D(jointPosition(hand: hand, finger: finger, joint: .pip)),
              let posWrist = extractPosition2D(jointPosition(hand: hand, finger: .wrist, joint: .tip)) else {
            return false
        }

        let tipToWristDistance = posWrist.distance(to: tipPosition)
        let secondToWristDistance = posWrist.distance(to: secondPosition)
        
        return secondToWristDistance < tipToWristDistance * 0.9
    }

    private func isThumbExtended(hand: Hands) -> Bool {
        guard let thumbTipPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .tip)),
              let thumbIPPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .pip)),
              let thumbCMCPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .mcp)) else {
            return false
        }

        let distalSegmentLength = thumbIPPosition.distance(to: thumbTipPosition)
        let proximalSegmentLength = thumbCMCPosition.distance(to: thumbIPPosition)
        
        let extensionThreshold = 1.2
        return distalSegmentLength > proximalSegmentLength * extensionThreshold
    }
    
    private func jointPosition(hand: Hands, finger: Fingers, joint: JointType) -> simd_float4x4? {
        let anchor = hand == .left ? leftHandAnchor : rightHandAnchor
        guard let skeleton = anchor?.handSkeleton else { return nil }

        let jointName: HandSkeleton.JointName
        switch (finger, joint) {
        case (.thumb, .tip): jointName = .thumbTip
        case (.thumb, .pip): jointName = .thumbIntermediateBase
        case (.thumb, .mcp): jointName = .thumbIntermediateTip
        case (.index, .tip): jointName = .indexFingerTip
        case (.index, .pip): jointName = .indexFingerIntermediateBase
        case (.middle, .tip): jointName = .middleFingerTip
        case (.middle, .pip): jointName = .middleFingerIntermediateBase
        case (.ring, .tip): jointName = .ringFingerTip
        case (.ring, .pip): jointName = .ringFingerIntermediateBase
        case (.little, .tip): jointName = .littleFingerTip
        case (.little, .pip): jointName = .littleFingerIntermediateBase
        case (.wrist, .tip): jointName = .wrist
        default: return nil
        }

        return skeleton.joint(jointName).anchorFromJointTransform
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
