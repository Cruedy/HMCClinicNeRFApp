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
    @Binding var box_center: [Float]
    @Binding var rotate_angle: Float
    @Binding var slider: [Float]
    let boundingbox = BoundingBox(center: [0,0,0])
//    var center: [Float] = [0,0,0]

    
    init(vm: ARViewModel, bv: Binding<Bool>, cet: Binding<[Float]>, rot: Binding<Float>, slider: Binding<[Float]>) {
        viewModel = vm
        _boxVisible = bv
        _box_center = cet
        _rotate_angle = rot
        _slider = slider
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let configuration = viewModel.createARConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isAutoFocusEnabled = true
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
//        configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats[4] // 1280x720
//        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
////            viewModel.appState.supportsDepth = true
//        }
        arView.debugOptions = [.showWorldOrigin]
        #if !targetEnvironment(simulator)
        arView.session.run(configuration)
        #endif

        arView.session.delegate = viewModel
        viewModel.session = arView.session
        viewModel.arView = arView
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
//        boundingbox.set_center(box_center)
//        boundingbox.set_angle(rotate_angle/180*3.1415926)
//        boundingbox.set_scale(slider)
//        
//        if (boxVisible) {
//            print("something changed OMG!")
//            
//            uiView.scene.anchors.removeAll()
//
//            let worldOriginAnchor = boundingbox.addNewBoxToScene()
//            
////            let worldOriginAnchor = viewModel.addNewBoxToScene()
//            uiView.scene.anchors.append(worldOriginAnchor)
////            let boxAnchor = viewModel.addBoxToScene()
////            uiView.scene.anchors.append(boxAnchor)
//        } else {
//            print("nothing")
//            uiView.scene.anchors.removeAll()
//        }
        
    }
    
}
