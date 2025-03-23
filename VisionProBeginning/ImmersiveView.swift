//
//  ImmersiveView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/21.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @State var route = 0
    
    var mainBgmPlayer: AVAudioPlayer?
    var endingBgmPlayer: AVAudioPlayer?
    
    init() {
        guard let mainBgmUrl = Bundle.main.url(forResource: "bgm_main", withExtension: "wav") else { return }
        
        guard let endingBgmUrl = Bundle.main.url(forResource: "bgm_ending", withExtension: "wav") else { return }
        
        do {
            self.mainBgmPlayer = try AVAudioPlayer(contentsOf: mainBgmUrl)
            self.endingBgmPlayer = try AVAudioPlayer(contentsOf: endingBgmUrl)
            mainBgmPlayer?.prepareToPlay()
            endingBgmPlayer?.prepareToPlay()
        } catch {
            self.mainBgmPlayer = nil
            self.endingBgmPlayer = nil
        }
    }
    
    var body: some View {
        Group {
            // routeによって画面を切り替える
            switch route {
            case 0: LookBackView {
                route = 1
            }.onAppear {
                mainBgmPlayer?.play()
            }.onDisappear {
                mainBgmPlayer?.setVolume(0, fadeDuration: 3)
            }
            case 1: DarkView {
                route = 2
            }
            default: ComeBackView()
                    .onAppear {
                        endingBgmPlayer?.play()
                    }
                    .onDisappear {
                        mainBgmPlayer?.currentTime = 0
                        mainBgmPlayer?.pause()
                        mainBgmPlayer?.volume = 1
                        endingBgmPlayer?.currentTime = 0
                        endingBgmPlayer?.pause()
                    }
            }
        }
        .gesture(TapGesture().targetedToEntity(BackSphereEntity.shared).onEnded { _ in
            Task { @MainActor in
                // イマーシブを終了する
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()
                
                // ウインドウを表示する
                openWindow(id: appModel.windowGroupID)
            }
        })
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
