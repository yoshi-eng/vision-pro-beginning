//
//  DarkView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct DarkView: View {
    @Environment(AppModel.self) private var appModel
    @State var bubbles: [String] = [] // 仮でString
    @State var isTurnedBack = false
    
    var onCatchLight: () -> Void
    
    // 振り返ったということにするエンティティ
    static let turnBackSphere = {
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .red, isMetallic: false)])
        
        // 自分の正面の1mの位置に配置
        model.position = SIMD3<Float>(2.0, 0.0, -5.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    
    // 光をつかんだということにするエンティティ
    static let comeBackLight = {
        let model = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
        
        // 自分の正面の1mの位置に配置
        model.position = SIMD3<Float>(-2.0, 0.0, -5.0)
        
        // Enable interactions on the entity.
        model.components.set(InputTargetComponent())
        model.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
        return model
    }()
    
    var body: some View {
        RealityView { content in
            content.add(BackSphereEntity.shared)
            
            // TODO: bubblesのエンティティを表示する
            
            // TODO: 一度振り返ったことを検知する → isTurnedBack = true
            content.add(DarkView.turnBackSphere)
            
            // TODO: isTurnedBack == true → 光を新たに表示する
            content.add(DarkView.comeBackLight)
            
        } update: { content in
            if let model = content.entities.first(where: { $0 == DarkView.comeBackLight }) as? ModelEntity {
                model.transform.scale = isTurnedBack ? [1.0, 1.0, 1.0] : [0.01, 0.01, 0.01]
            }
        }
        .gesture(TapGesture().targetedToEntity(DarkView.turnBackSphere).onEnded { _ in
            // 振り返ったということにする
            isTurnedBack.toggle()
        })
        .gesture(TapGesture().targetedToEntity(DarkView.comeBackLight).onEnded { _ in
            // 光をつかんだということにする
            onCatchLight()
        })
    }
}

