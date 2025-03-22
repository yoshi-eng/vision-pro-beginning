//
//  ToImmersiveButton.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI

struct ToImmersiveButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    var text: String
    
    var body: some View {
        Button {
            Task { @MainActor in
                // イマーシブを展開する
                appModel.immersiveSpaceState = .inTransition
                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                case .opened:
                    // Don't set immersiveSpaceState to .open because there
                    // may be multiple paths to ImmersiveView.onAppear().
                    // Only set .open in ImmersiveView.onAppear().
                    break
                    
                case .userCancelled, .error:
                    // On error, we need to mark the immersive space
                    // as closed because it failed to open.
                    fallthrough
                @unknown default:
                    // On unknown response, assume space did not open.
                    appModel.immersiveSpaceState = .closed
                }
            }
        } label: {
            Text(text)
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
