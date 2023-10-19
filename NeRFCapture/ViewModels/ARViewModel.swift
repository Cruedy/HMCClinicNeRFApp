//
//  ARViewModel.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import Foundation
import Zip
import Combine
import ARKit
import RealityKit
import os.log
enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

class ARViewModel : NSObject, ARSessionDelegate, ObservableObject {
    @Published var appState = AppState()
    var session: ARSession? = nil
    var arView: ARView? = nil
//    let frameSubject = PassthroughSubject<ARFrame, Never>()
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    let ddsWriter: DDSWriter
    
    init(datasetWriter: DatasetWriter, ddsWriter: DDSWriter) {
        self.datasetWriter = datasetWriter
        self.ddsWriter = ddsWriter
        super.init()
        self.setupObservers()
        self.ddsWriter.setupDDS()
    }
    
    func setupObservers() {
        datasetWriter.$writerState.sink {x in self.appState.writerState = x} .store(in: &cancellables)
        datasetWriter.$currentFrameCounter.sink { x in self.appState.numFrames = x }.store(in: &cancellables)
        ddsWriter.$peers.sink {x in self.appState.ddsPeers = UInt32(x)}.store(in: &cancellables)
        
        $appState
            .map(\.appMode)
            .prepend(appState.appMode)
            .removeDuplicates()
            .sink { x in
                switch x {
                case .Offline:
                    os_log("This is a default log message")

//                    self.appState.stream = false
                    print("Changed to offline")
                case .Online:
                    os_log("This is a default log message")

                    print("Changed to online")
                }
            }
            .store(in: &cancellables)
        
//        frameSubject.throttle(for: 0.5, scheduler: RunLoop.main, latest: true).sink {
//            f in
//            if self.appState.stream && self.appState.appMode == .Online {
//                self.ddsWriter.writeFrameToTopic(frame: f)
//            }
//        }.store(in: &cancellables)
    }
    
    
    func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            // Activate sceneDepth
            configuration.frameSemantics = .sceneDepth
        }
        return configuration
    }
    
    func resetWorldOrigin() {
        session?.pause()
        let config = createARConfiguration()
        session?.run(config, options: [.resetTracking])
    }
    
//    func createEmptyBoundingBox() -> {
//        guard let arView = arView else {return ARAnchor()}
//        let cubeGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
//        let cubeNode = SCNNode(geometry: cubeGeometry)
//        
//        let anchor = ARAnchor(transform: cubeNode.simdTransform)
//        
//        return anchor
////        arView.session.add(anchor: anchor)
//        
////        arView.session.rootNode.addChildNode(cubeNode)
//    }
//    
    
    func createLine(corners: [[Float]], thickness: Float) -> MeshDescriptor{
        var positions: [SIMD3<Float>] = []
        
        var descr = MeshDescriptor(name: "line")

        for corner in corners {
            positions.append(SIMD3<Float>([corner[0]+thickness, corner[1], corner[2]]))
            positions.append(SIMD3<Float>([corner[0]-thickness, corner[1], corner[2]]))
            positions.append(SIMD3<Float>([corner[0], corner[1]+thickness, corner[2]]))
            positions.append(SIMD3<Float>([corner[0], corner[1]-thickness, corner[2]]))
        }
        descr.positions = MeshBuffers.Positions(positions[0...7])
        descr.primitives = .polygons([4, 4, 4, 4, 4, 4], [1, 2, 0, 3,  // front
                                                          5, 6, 4, 7,  // back
                                                          2, 0, 4, 6,  // top
                                                          2, 1, 5, 6,  // bottom
                                                          0, 3, 7, 4,  // left
                                                          1, 3, 7, 5]) // right
        
        return descr
        
    }
    func createBoundingBox(corners: [[Float]], thickness: Float) -> [MeshDescriptor] {
        let faces = [[0, 1, 2, 3],  // front
                      [4, 5, 6, 7],  // back
                      [3, 2, 6, 7],  // top
                      [0, 1, 5, 4],  // bottom
                      [4, 0, 3, 7],  // left
                      [1, 5, 6, 2]]  // right
        var line_descrs: [MeshDescriptor] = []
        for face in faces {
            var point1 = 3
            for point2 in 0...3 {
                print([corners[face[point1]],corners[face[point2]]])
                line_descrs.append(createLine(corners: [corners[face[point1]],corners[face[point2]]], thickness:thickness))
                point1 = point2
            }
        }
        return line_descrs
        
//        var positions: [SIMD3<Float>] = []
//        for corner in corners {
//            positions.append([corner[0] + thickness, corner[1], corner[2]])
//            positions.append([corner[0] - thickness, corner[1], corner[2]])
//        }
//    
//        
//        var descr = MeshDescriptor(name: "cube")
//        descr.positions = MeshBuffers.Positions(positions[0...15])
//        let groupings: [UInt8] = Array(repeating: 4, count: 12)
//        let faces = [[0, 1, 2, 3],  // front
//                      [4, 5, 6, 7],  // back
//                      [3, 2, 6, 7],  // top
//                      [0, 1, 5, 4],  // bottom
//                      [4, 0, 3, 7],  // left
//                      [1, 5, 6, 2]]  // right
//        var orderings: [UInt32] = []
//        for face in faces {
//            var point1_idx = 3
//            for point2_idx in 0...3 {
//                let point1 = face[point1_idx]
//                let point2 = face[point2_idx]
//                orderings.append(UInt32(2*point1))
//                orderings.append(UInt32(2*point1+1))
//                orderings.append(UInt32(2*point2+1))
//                orderings.append(UInt32(2*point2))
//                point1_idx = point2_idx
//            }
//        }
//        descr.primitives = .polygons(groupings, orderings)
//        return descr
    }
    
    func addNewBoxToScene() -> AnchorEntity{
        guard let arView = arView else { return AnchorEntity(world: [0, 2, -1])}
        let worldOriginAnchor = AnchorEntity(world:.zero)
        let positions: [[Float]] = [[-0.5, -0.5, -2], [0.5, -0.5, -2], [0.5, 0.5, -2], [-0.5, 0.5, -2],
                                         [-0.5, -0.5, -3], [0.5, -0.5, -3], [0.5, 0.5, -3], [-0.5, 0.5, -3]]
//        let colors: [Material.Color] = [.red, .white, .blue, .green]
//        
//        var descr = MeshDescriptor(name: "cube")
//        descr.positions = MeshBuffers.Positions(positions[0...7])
//        descr.primitives = .polygons([4, 4, 4, 4, 4, 4], [0, 1, 2, 3,  // front
//                                                          4, 5, 6, 7,  // back
//                                                          3, 2, 6, 7,  // top
//                                                          0, 1, 5, 4,  // bottom
//                                                          4, 0, 3, 7,  // left
//                                                          1, 5, 6, 2]) // right
        
//        let positions: [SIMD3<Float>] = [[-0.5, -0.5, -2], [-0.4, -0.5, -2], [0.5, -0.5, -2], [0.4, -0.5, -2], [0.5, 0.5, -2], [0.4, 0.5, -2], [-0.5, 0.5, -2], [-0.4, 0.5, -2],
//                                         [-0.5, -0.5, -3], [-0.4, -0.5, -3], [0.5, -0.5, -3], [0.4, -0.5, -3], [0.5, 0.5, -3], [0.4, 0.5, -3], [-0.5, 0.5, -3], [-0.4, 0.5, -3]]
//        let colors: [Material.Color] = [.red, .white, .blue, .green]
//        
//        var descr = MeshDescriptor(name: "cube")
//        descr.positions = MeshBuffers.Positions(positions[0...7])
//        descr.primitives = .polygons([4, 4, 4, 4, 4, 4], [0, 1, 2, 3,  // front
//                                                          4, 5, 6, 7,  // back
//                                                          3, 2, 6, 7,  // top
//                                                          0, 1, 5, 4,  // bottom
//                                                          4, 0, 3, 7,  // left
//                                                          1, 5, 6, 2]) // right
        var descrs = createBoundingBox(corners: positions, thickness: 0.1)
//        var descr = createLine(corners: [[-0.5, -0.5, -2], [0.5, -0.5, -2]], thickness: 0.01)
        for descr in descrs {
            let material = SimpleMaterial(color: .orange, isMetallic: false)
            
            let generatedModel = ModelEntity(
               mesh: try! .generate(from: [descr]),
               materials: [material]
            )
            
            worldOriginAnchor.addChild(generatedModel)
        }
        
        return worldOriginAnchor
    }
    
    func addBoxToScene() -> AnchorEntity {
        guard let arView = arView else { return AnchorEntity(world: [0, 2, -1])}
        
        let box = MeshResource.generateBox(size: 1)
//        let material = SimpleMaterial(color: .green, isMetallic: false)
        var wireframeMaterial = SimpleMaterial(color: .blue, isMetallic: true)
//        wireframeMaterial.tintColor = .white
//        boxMesh.materials = [wireframeMaterial]
        
        
//        wireframeMaterial.color = try! MaterialColorParameter.texture(TextureResource.load(named: "wireframe"))
//        wireframematerial.color.tiling = .init(repeating: .one)
//        wireframeMaterial.baseColor.mipFilter = .linear
//        wireframeMaterial.baseColor.wrapMode = .repeat
//        wireframeMaterial.metallic = 1
//        wireframeMaterial.roughness = 1
//        wireframeMaterial.alpha = 1
        
        let boxEntity = ModelEntity(mesh: box, materials: [wireframeMaterial])
        
        let anchor = AnchorEntity(world: [0, 0, -1]) // Position the box in front of the camera
//        let anchor = AnchorEntity(plane: .horizontal)
        
        anchor.addChild(boxEntity)
        return anchor
        
//        arView.scene.addAnchor(anchor)
    }
    
    
    func session(
        _ session: ARSession,
        didUpdate frame: ARFrame
    ) {
//        frameSubject.send(frame)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
    }
}
