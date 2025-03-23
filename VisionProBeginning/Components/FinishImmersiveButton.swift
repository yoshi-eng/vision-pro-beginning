//
//  FinishImmersiveButton.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI

struct FinishImmersiveButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    var text: String
    
    var body: some View {
        Button {
            Task { @MainActor in
                // イマーシブを終了する
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
                
                // ウインドウを表示する
                openWindow(id: appModel.windowGroupID)
            }
        } label: {
            Text(text)
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
        // ボタンの位置を調整
        .transformEffect(.init(translationX: 0, y: 0))
        // ユーザーの前方に配置（Z距離を調整）
        .offset(z: -0.5)
    }
}
