//
//  ARView.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    @Binding var boxVisible: Bool
    @Binding var moveLeft: Bool
    @Binding var moveRight: Bool
    @Binding var rotate45: Bool
    let boundingbox = BoundingBox(center: [0,0,0])

    
    init(vm: ARViewModel, bv: Binding<Bool>, ml: Binding<Bool>, mr: Binding<Bool>, rot: Binding<Bool>) {
        viewModel = vm
        _boxVisible = bv
        _moveLeft = ml
        _moveRight = mr
        _rotate45 = rot
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let configuration = viewModel.createARConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = true
//        configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats[4] // 1280x720
//        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
////            viewModel.appState.supportsDepth = true
//        }
        arView.debugOptions = [.showWorldOrigin]
        #if !targetEnvironment(simulator)
        arView.session.run(configuration)
        #endif
//        placeBlueBlock()
        
//        let block = MeshResource.generateBox(size: 1)
//        let material = SimpleMaterial(color: .blue, isMetallic:  false)
//        let entity = ModelEntity(mesh: block, materials: [material])
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(entity)
//        arView.scene.addAnchor(anchor)
//        viewModel.addBoxToScene()

        arView.session.delegate = viewModel
        viewModel.session = arView.session
        viewModel.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if (boxVisible) {
            print("something changed OMG!")
            uiView.scene.anchors.removeAll()

//            boundingbox.update_center([0.1,0.1,0.1])
            boundingbox.set_scale([0.3, 0.3, 0.3])
            let worldOriginAnchor = boundingbox.addNewBoxToScene()
            
//            let worldOriginAnchor = viewModel.addNewBoxToScene()
            uiView.scene.anchors.append(worldOriginAnchor)
//            let boxAnchor = viewModel.addBoxToScene()
//            uiView.scene.anchors.append(boxAnchor)
        } else {
            print("nothing")
            uiView.scene.anchors.removeAll()
        }
        
        if (moveLeft) {
            uiView.scene.anchors.removeAll()
            print(uiView.cameraTransform.matrix)
//            print(uiView.cameraTransform.matrix * [-0.1, 0, 0, 1])
//            var transform = uiView.cameraTransform.matrix
//            transform[0][3] = 0
//            transform[1][3] = 0
//            transform[2][3] = 0
//            var world_movement = transform * [-0.1, 0, 0, 1]
//            print(world_movement)
//            boundingbox.update_center([world_movement[0], world_movement[1], world_movement[2]])
            boundingbox.update_center([-0.1, 0, 0])
            let worldOriginAnchor = boundingbox.addNewBoxToScene()
            uiView.scene.anchors.append(worldOriginAnchor)

            print("should move left")
        }
        if(moveRight){
            uiView.scene.anchors.removeAll()
            print(uiView.cameraTransform.matrix)
//            print(uiView.cameraTransform.matrix * [0.1, 0, 0, 1])
//            var transform = uiView.cameraTransform.matrix
//            transform[0][3] = 0
//            transform[1][3] = 0
//            transform[2][3] = 0
//            var world_movement = transform * [0.1, 0, 0, 1]
//            print(world_movement)
//            boundingbox.update_center([world_movement[0], world_movement[1], world_movement[2]])
            boundingbox.update_center([0.1, 0, 0])
            let worldOriginAnchor = boundingbox.addNewBoxToScene()
            uiView.scene.anchors.append(worldOriginAnchor)
            
            print("should move right")
        }
        if(rotate45){
            uiView.scene.anchors.removeAll()
            boundingbox.update_angle(Float.pi/4)
            let worldOriginAnchor = boundingbox.addNewBoxToScene()
            uiView.scene.anchors.append(worldOriginAnchor)
            
            print("should rotate 45 degrees counterclockwise")
            
        }
        
    }
    
//    func addBoxToScene() {
////        guard let arView = arView else { return }
//        
//        let box = MeshResource.generateBox(size: 1)
//        let material = SimpleMaterial(color: .green, isMetallic: false)
//        let boxEntity = ModelEntity(mesh: box, materials: [material])
//        
//        let anchor = AnchorEntity(world: [0, 0, -1]) // Position the box in front of the camera
////        let anchor = AnchorEntity(plane: .horizontal)
//
//        anchor.addChild(boxEntity)
//        
//        arView.scene.addAnchor(anchor)
//    }
//    
    
//    func placeBlueBlock(){
//        let block = MeshResource.generateBox(size: 1)
//        let material = SimpleMaterial(color: .blue, isMetallic: false)
//        let entity = ModelEntity(mesh: block, materials: [material])
//        
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(entity)
//        viewModel.arView?.scene.addAnchor(anchor)
//        
////        /*scene*/.add(anchor: anchor)
//    }
}
