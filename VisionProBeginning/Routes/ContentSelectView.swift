//
//  ContentSelectView.swift
//  VisionProBeginning
//
//  Created by d on 2025/03/22.
//

import SwiftUI
import RealityKit
import RealityKitContent
import PhotosUI

struct ContentSelectView: View {
    @State var photos: [PhotosPickerItem] = []
    @State var images: [UIImage] = []
    
    var body: some View {
        VStack {
            if !photos.isEmpty {
                PhotosPicker(selection: $photos) {
                    Text("思い出を選ぶ")
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .padding()
                }
                HStack {
                    PhotosPicker(selection: $photos) {
                        Text("選び直す")
                    }
                    ToImmersiveButton(text: "思い出を振り返ろう")
                }
            }
        }
        .padding()
        .task(id: photos) {
            do {
                images.removeAll()
                for photo in photos {
                    if let data = try await photo.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentSelectView()
        .environment(AppModel())
}
