import SwiftUI
import RealityKit
import AVFoundation
import CoreMedia
import Combine
import RealityKitContent

// MARK: - Video Info Model
@Observable
class VideoInfo: Identifiable {
    let id = UUID()
    var isSpatial: Bool = false
    var size: CGSize = .zero
    var projectionType: CMProjectionType?
    var horizontalFieldOfView: Float?
    var position: SIMD3<Float>
    
    init(position: SIMD3<Float> = SIMD3<Float>(0, 0, -50)) {
        self.position = position
    }
    
    var sizeString: String {
        size == .zero ? "未指定" :
            String(format: "%.0fx%.0f", size.width, size.height) + (isSpatial ? " (片目)" : "")
    }
    
    var projectionTypeString: String {
        switch projectionType {
        case .rectangular:
            return "平面 (Rectilinear)"
        case .equirectangular:
            return "360度 (Equirectangular)"
        case .halfEquirectangular:
            return "180度 (Half Equirectangular)"
        case .fisheye:
            return "魚眼 (Fisheye)"
        default:
            return "未指定"
        }
    }
    
    var horizontalFieldOfViewString: String {
        horizontalFieldOfView.map { String(format: "%.0f°", $0) } ?? "未指定"
    }
}

// MARK: - Video Tools
struct VideoTools {
    // 動画のメタデータ情報を取得する
    static func getVideoInfo(asset: AVAsset, existingInfo: VideoInfo? = nil) async -> VideoInfo? {
        // 既存の情報があれば再利用し、なければ新規作成
        let videoInfo = existingInfo ?? VideoInfo()
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            print("ビデオトラックが見つかりません")
            return nil
        }
        
        // トラックのプロパティを読み込む
        guard let (naturalSize, formatDescriptions, mediaCharacteristics) = try? await videoTrack.load(
            .naturalSize, .formatDescriptions, .mediaCharacteristics
        ),
        let formatDescription = formatDescriptions.first else {
            print("ビデオプロパティの読み込みに失敗しました")
            return nil
        }
        
        videoInfo.size = naturalSize
        // 空間(ステレオ)コンテンツかどうかを判定
        videoInfo.isSpatial = mediaCharacteristics.contains(.containsStereoMultiviewVideo)
        
        // プロジェクションタイプとFOVを取得
        let projection = getProjection(formatDescription: formatDescription)
        videoInfo.projectionType = projection.projectionType
        videoInfo.horizontalFieldOfView = projection.horizontalFieldOfView
        
        return videoInfo
    }
    
    // フォーマット記述からプロジェクションタイプと水平視野角を抽出
    static func getProjection(formatDescription: CMFormatDescription)
        -> (projectionType: CMProjectionType?, horizontalFieldOfView: Float?) {
        var projectionType: CMProjectionType?
        var horizontalFieldOfView: Float?
        
        if let extensionsDict = CMFormatDescriptionGetExtensions(formatDescription) as Dictionary? {
            // プロジェクションタイプの取得
            if let projectionKind = extensionsDict["ProjectionKind" as CFString] as? String {
                switch projectionKind {
                case "Rectilinear":
                    projectionType = .rectangular
                case "Equirectangular":
                    projectionType = .equirectangular
                case "HalfEquirectangular":
                    projectionType = .halfEquirectangular
                case "Fisheye":
                    projectionType = .fisheye
                default:
                    projectionType = .rectangular
                }
            }
            
            // 水平視野角の取得
            if let hfovValue = extensionsDict[kCMFormatDescriptionExtension_HorizontalFieldOfView] as? UInt32 {
                // 値はミリ度単位で保存されている
                horizontalFieldOfView = Float(hfovValue) / 1000.0
            }
        }
        
        return (projectionType, horizontalFieldOfView)
    }
    
    // 平面ビデオ用のスケールファクターを計算
    static func calculateScaleFactor(
        videoWidth: Float,
        videoHeight: Float,
        zDistance: Float,
        fovDegrees: Float
    ) -> Float {
        let fovRadians = fovDegrees * .pi / 180.0
        let halfWidthAtZDistance = zDistance * tan(fovRadians / 2.0)
        return 2.0 * halfWidthAtZDistance
    }
    
    // ビデオ情報に基づいてメッシュとトランスフォームを生成
    static func makeVideoMesh(videoInfo: VideoInfo) async -> (mesh: MeshResource, transform: Transform)? {
        // 基準距離
        let zDistance: Float = 10.0
        let horizontalFieldOfView = videoInfo.horizontalFieldOfView ?? 65.0
        
        // 平面メッシュを作成（通常の立体視用）
        let ratio = Float(videoInfo.size.height / videoInfo.size.width)
        let width: Float = 1.0
        let height: Float = width * ratio
        
        // 平面メッシュを生成
        let mesh = await MeshResource.generatePlane(width: width, depth: height)
        
        // スケールを調整
        let scale = calculateScaleFactor(
            videoWidth: width, videoHeight: height,
            zDistance: zDistance, fovDegrees: horizontalFieldOfView
        ) * 2 //* 0.5 // 少し小さめに
        
        // 基本的な変換行列（位置は後で設定）
        let transform = Transform(
            scale: .init(x: scale, y: 1, z: scale),
            rotation: .init(angle: Float.pi / 2, axis: .init(x: 1, y: 0, z: 0)),
            translation: .zero // 位置は呼び出し側で設定
        )
        
        return (mesh: mesh, transform: transform)
    }
    
    // ポータル用の円形メッシュを生成
    static func createPortalMesh(radius: Float) -> MeshResource {
        // 円形のポータルメッシュを生成（cornerRadiusを半分のサイズにすると円になる）
        return .generatePlane(width: radius * 2,
                             depth: radius * 2,
                             cornerRadius: radius)
    }
    
    // ポータルフレームのマテリアルを作成
    static func createPortalMaterial() -> SimpleMaterial {
        // 輝く青いマテリアル（ポータル用）
        let material = SimpleMaterial(
            color: .init(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.8),
            roughness: 0.2,
            isMetallic: true
        )
        
        return material
    }
    
    // フレーム用の簡単なマテリアルを作成（ポータルの周りに追加の装飾用）
    static func createFrameMaterial() -> SimpleMaterial {
        return SimpleMaterial(
            color: .init(red: 0.1, green: 0.7, blue: 1.0, alpha: 0.9),
            roughness: 0.1,
            isMetallic: true
        )
    }
}

// MARK: - View Model
@Observable
class PlayerViewModel {
    var videos: [VideoInfo] = []
    var isImmersiveSpaceShown: Bool = false
    var isSpatialVideoAvailable: Bool = false
    var shouldPlayInStereo: Bool = true

    init() {
        // 4個のビデオを配置
        let videoCount = 1
        
        // 間隔と基準位置（2x2のグリッド）
        let spacing: Float = 15.0 // より広い間隔に
        let depth: Float = -40.0  // より遠くに配置
        
        let positions = [
            SIMD3<Float>(-spacing/2, spacing/2, depth), // 左上
            SIMD3<Float>(spacing/2, spacing/2, depth),  // 右上
            SIMD3<Float>(-spacing/2, -spacing/2, depth), // 左下
            SIMD3<Float>(spacing/2, -spacing/2, depth)   // 右下
        ]
        
        for i in 0..<videoCount {
            // 新しいビデオ情報を作成
            let videoInfo = VideoInfo(position: positions[i])
            videos.append(videoInfo)
        }
    }

    var isStereoEnabled: Bool {
        isSpatialVideoAvailable && shouldPlayInStereo
    }
}

// MARK: - Immersive Player View
struct ImmersiveView: View {
    @Bindable var viewModel: PlayerViewModel
    @State private var players: [AVPlayer] = []
    @State private var videoMaterials: [VideoMaterial] = []
    @State private var videoEntities: [Entity] = []
    @State private var frameEntities: [Entity] = []

    var body: some View {
        RealityView { content in
            // 不要なエンティティをクリア
            videoEntities.forEach { $0.removeFromParent() }
            videoEntities.removeAll()
            frameEntities.forEach { $0.removeFromParent() }
            frameEntities.removeAll()
            players.removeAll()
            videoMaterials.removeAll()
            
            // 各ビデオに対して処理を実行
            for (index, videoPosition) in viewModel.videos.enumerated() {
                // ビデオファイル名（すべて同じビデオを使用）
                let fileName = "video1"
                
                guard let url = Bundle.main.url(forResource: fileName, withExtension: "mov") else {
                    print("\(fileName).movが見つかりません")
                    continue
                }
                
                let asset = AVURLAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)
                let player = AVPlayer()
                players.append(player)

                // 現在のビデオ情報を取得（位置情報も保持）
                let currentVideoInfo = videoPosition
                
                // ビデオ情報を更新（位置情報は維持）
                guard let updatedVideoInfo = await VideoTools.getVideoInfo(asset: asset, existingInfo: currentVideoInfo) else {
                    print("ビデオ情報の取得に失敗しました")
                    continue
                }

                // ビューモデルを更新
                DispatchQueue.main.async {
                    self.viewModel.videos[index] = updatedVideoInfo
                    if updatedVideoInfo.isSpatial {
                        self.viewModel.isSpatialVideoAvailable = true
                    }
                }

                // ビデオプレーン用のメッシュとトランスフォームを取得
                guard let (_, baseTransform) = await VideoTools.makeVideoMesh(videoInfo: updatedVideoInfo) else {
                    print("ビデオメッシュの作成に失敗しました")
                    continue
                }

                // ビデオマテリアルを作成
                let videoMaterial = VideoMaterial(avPlayer: player)
                videoMaterials.append(videoMaterial)
                
                // ステレオモードを設定
                videoMaterial.controller.preferredViewingMode = viewModel.isStereoEnabled ? .stereo : .mono
                
                // 円形ポータル用のメッシュを作成
                let portalRadius: Float = 0.4
                let portalMesh = VideoTools.createPortalMesh(radius: portalRadius)
                
                // ビデオ表示用エンティティを作成（円形メッシュを使用）
                let videoEntity = ModelEntity(mesh: portalMesh, materials: [videoMaterial])
                
                // ビデオが正面を向くようにスケールと回転を設定
                videoEntity.transform.scale = baseTransform.scale
                videoEntity.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: SIMD3<Float>(1, 0, 0))
                videoEntity.transform.translation = updatedVideoInfo.position
                
                // 装飾用のフレームを追加
                let frameThickness: Float = 0.05
                let outerFrameRadius = portalRadius + frameThickness
                let frameMesh = VideoTools.createPortalMesh(radius: outerFrameRadius)
                let frameMaterial = VideoTools.createFrameMaterial()
                
                // フレームエンティティの作成
                let frameEntity = ModelEntity(mesh: frameMesh, materials: [frameMaterial])
                frameEntity.transform = videoEntity.transform
                // フレームを少し後ろに配置
                frameEntity.transform.translation.z += 0.01
                
                // エンティティをシーンに追加（フレームが後ろに見えるように先に追加）
                content.add(frameEntity)
                content.add(videoEntity)
                
                videoEntities.append(videoEntity)
                frameEntities.append(frameEntity)
                
                // 再生開始
                player.replaceCurrentItem(with: playerItem)
                player.play()
                
                logger.debug("video \(index) is played")
            }
        }
        .onChange(of: viewModel.shouldPlayInStereo) { _, newValue in
            // ステレオ/モノ設定が変更されたときにマテリアルを更新
            updateStereoMode()
        }
    }

    // ステレオモードを更新
    func updateStereoMode() {
        for material in videoMaterials {
            material.controller.preferredViewingMode = viewModel.isStereoEnabled ? .stereo : .mono
        }
    }
}

// MARK: - Content View (UI)
struct ContentView: View {
    @Bindable var viewModel: PlayerViewModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack {
            Text("マルチビデオ Spatialプレーヤー")
                .font(.title)
                .padding()
            
            if viewModel.isImmersiveSpaceShown {
                // ビデオ情報を表示
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.videos) { videoInfo in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("ビデオ \(videoInfo.id)")
                                    .font(.headline)
                                HStack {
                                    Text("空間ビデオ：").bold()
                                    Text(videoInfo.isSpatial ? "あり" : "なし")
                                }
                                HStack {
                                    Text("サイズ：").bold()
                                    Text(videoInfo.sizeString)
                                }
                                HStack {
                                    Text("プロジェクション：").bold()
                                    Text(videoInfo.projectionTypeString)
                                }
                                HStack {
                                    Text("水平視野角：").bold()
                                    Text(videoInfo.horizontalFieldOfViewString)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                Toggle("ステレオモードで再生", isOn: $viewModel.shouldPlayInStereo)
                    .fixedSize()
                    .disabled(!viewModel.isSpatialVideoAvailable)
                    .padding(.bottom)
                
                Button("再生停止", systemImage: "stop.fill") {
                    stopPlayback()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding()
            } else {
                Text("複数のvideo1.movを再生するアプリです")
                    .padding()
                
                Button("再生開始", systemImage: "play.fill") {
                    startPlayback()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding()
            }
        }
    }
    
    // 再生開始
    func startPlayback() {
        Task {
            switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
            case .opened:
                viewModel.isImmersiveSpaceShown = true
            default:
                viewModel.isImmersiveSpaceShown = false
            }
        }
    }
    
    // 再生停止
    func stopPlayback() {
        Task {
            await dismissImmersiveSpace()
            viewModel.isImmersiveSpaceShown = false
        }
    }
}

// MARK: - Custom Components
struct WorldComponent: Component {
    init() {}
}

struct PortalComponent: Component {
    var target: Entity
    
    init(target: Entity) {
        self.target = target
    }
}
