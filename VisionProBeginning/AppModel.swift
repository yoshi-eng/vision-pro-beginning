//
//  AppModel.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let windowGroupID = "WindowGroup"
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
