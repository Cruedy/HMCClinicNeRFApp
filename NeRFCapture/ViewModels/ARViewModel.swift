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
    @Published var isFlashVisible = false
    var session: ARSession? = nil
    var arView: ARView? = nil
//    let frameSubject = PassthroughSubject<ARFrame, Never>()
    let boundingbox = BoundingBox(center: [0,0,0])
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    let ddsWriter: DDSWriter
    var boundingBoxAnchor: AnchorEntity? = nil
    var boxVisible = true
    var cameraTimer: Timer?
    
    init(datasetWriter: DatasetWriter, ddsWriter: DDSWriter) {
        self.datasetWriter = datasetWriter
        self.ddsWriter = ddsWriter
        super.init()
        self.subscribeToActionStream()
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
                    // we will only have offline mode
                case .Offline:
                    os_log("This is a default log message")
                    print("Changed to offline")
                }
            }
            .store(in: &cancellables)
    }
    
    // Actions from BoundingBoxView to update the boundingbox
    func subscribeToActionStream() {
            ActionManager.shared
                .actionStream
                .sink { [weak self] action in
                    
                    switch action {
                    case .heartbeat(let data):
                        print(data)
                    
                        // each action involves performing the action, rendering and updating the bounding box information
                    case .display_box(let boxVisible):
                        self?.display_box(boxVisible: boxVisible)
                        self?.boxVisible = boxVisible
                        self?.update_boundingbox_manifest()
                        
                    case .set_center(let new_center):
                        self?.set_center(new_center: new_center)
                        self?.display_box(boxVisible: self!.boxVisible)
                        self?.update_boundingbox_manifest()

                        
                    case .set_angle(let new_angle):
                        self?.set_angle(new_angle: new_angle)
                        self?.display_box(boxVisible: self!.boxVisible)
                        self?.update_boundingbox_manifest()


                    case .set_scale(let new_scale):
                        self?.set_scale(new_scale: new_scale)
                        self?.display_box(boxVisible: self!.boxVisible)
                        self?.update_boundingbox_manifest()

                    
                    case .extend_sides(let scale_update):
                        self?.extend_sides(offset: scale_update)
                        self?.display_box(boxVisible: self!.boxVisible)
                        self?.update_boundingbox_manifest()

                        
                    case .shrink_sides(let scale_update):
                        self?.shrink_sides(offset: scale_update)
                        self?.display_box(boxVisible: self!.boxVisible)
                        self?.update_boundingbox_manifest()
                        
                    case .raycast_center(let at, let frame):
                        self?.raycast_bounding_box_center(at:at, frame: frame)
                        self?.display_box(boxVisible: self!.boxVisible)
                    
                    case .set_floor(let at, let frame):
                        self?.findFloorHeight(at: at, frame: frame)
                        self?.display_box(boxVisible: self!.boxVisible)
                    
                    }
                }
                .store(in: &cancellables)
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
    
    func display_box(boxVisible: Bool) {
        if (boxVisible){        
            print("displaying box")

            if boundingBoxAnchor != nil{
                arView?.scene.removeAnchor(boundingBoxAnchor!)
            }
            boundingBoxAnchor = boundingbox.addNewBoxToScene()
            arView?.scene.anchors.append(boundingBoxAnchor!)
        } else {
            print("not displaying box")

            if boundingBoxAnchor != nil{
                arView?.scene.removeAnchor(boundingBoxAnchor!)
            }
        }
        update_boundingbox_manifest()
    }
    
    func set_center(new_center: [Float]) -> [Float] {
        let center = boundingbox.set_center(new_center) // a bit of a misnomer rn this should be the actual position not offset
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return center
    }
    
    func set_angle(new_angle: Float) -> Float {
        print("got angle")
        let angle = boundingbox.set_angle(new_angle/180*3.1415926)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return new_angle
    }
    
    func set_scale(new_scale: [Float]) -> [Float] {
        print("got scale")
        let scale = boundingbox.set_scale(new_scale)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return scale
    }
    
    func extend_sides(offset: [Float]) -> ([Float], [Float]){
        print("extending side")
        let (center, scale) = boundingbox.extend_side(offset)
        update_boundingbox_manifest()
        return (center, scale)
    }
    
    func shrink_sides(offset: [Float]) -> ([Float], [Float]){
        print("shrink side")
        let (center, scale) = boundingbox.shrink_side(offset)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return (center, scale)
    }
    
//    func get_box_scale() -> [Float]{
//        return boundingbox.scale;
//    }
//    
//    func get_box_center() -> [Float]{
//        return boundingbox.center;
//    }
//    
//    func get_box_rotation() -> Float{
//        return boundingbox.rot_y
//    }
    
    func raycast_bounding_box_center(at screenPoint: CGPoint, frame: ARFrame) -> [Float]{
        
        // Check if arView is not nil
        guard let arView = arView else {
            print("arView is nil")
            return boundingbox.center
        }
        
        // Calculate the screen center
//        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        
        // Perform the raycast
//        let raycastResults = arView.raycast(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
        let raycastResults = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .any)

        
        // Check if there are any raycast results
        guard let hitResult = raycastResults.first else {
            print("No raycast results found")
            return boundingbox.center
        }
        // Use the hitResult to get the point of intersection
        let translationMatrix = SIMD4<Float>(0, 0, 0, 1)
        let translation = hitResult.worldTransform * translationMatrix
        let userFocusPoint = SIMD3<Float>(translation.x, translation.y, translation.z)

        let center = boundingbox.set_center_xy(newCenter: userFocusPoint)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return center
    }
    
    func findFloorHeight(at screenPoint: CGPoint, frame: ARFrame){
        print("Find Floor height")
        
        // Check if arView is not nil
        guard let arView = arView else {
            print("arView is nil")
            return
        }
        
        // Calculate the screen center
//        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        
        // Perform the raycast
//        let raycastResults = arView.raycast(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal)
        let raycastResults = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal)

        // Check if there are any raycast results
        guard let hitResult = raycastResults.first else {
            print("No raycast results found")
            return
        }
        
        // Use the hitResult to get the focus point
        let translationMatrix = SIMD4<Float>(0, 0, 0, 1) // Create a vector at the origin
//        let translation = worldTransform * translationMatrix
//        let translationVector = SIMD3<Float>(translation.x, translation.y, translation.z)
        let translation = hitResult.worldTransform * translationMatrix
//        let userFocusPoint = SIMD3<Float>(translation.x, translation.y, translation.z)

        // Assuming boundingbox is your BoundingBoxView instance
//        boundingbox.updateBoundingBoxUsingPointCloud(frame: frame, focusPoint: userFocusPoint)
        print("""

    Height: \(translation.y)

    """)
        boundingbox.setFloor(height: translation.y)
    }
    
    
    func update_boundingbox_manifest(){
        print("creating json from bounding box")
        let boundingBoxManifest = boundingbox.encode_as_json()
        datasetWriter.boundingBoxManifest = boundingBoxManifest
        print(boundingBoxManifest)
    }
    
    func resetWorldOrigin() {
        session?.pause()
        let config = createARConfiguration()
        session?.run(config, options: [.resetTracking])
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
    
    func get_bbox_scales() -> [Float] {
        return self.boundingbox.scale
    }
    
    func startAutomaticCapture() {
        cameraTimer?.invalidate()
        // Schedule a new timer to call writeFrameToDisk every 5 seconds
        cameraTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            if let frame = self.session?.currentFrame {
                self.datasetWriter.writeFrameToDisk(frame: frame)
                // Trigger the flash effect
                self.isFlashVisible = true
                // Hide flash after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isFlashVisible = false
                }
            }
        }
    }
    
    func stopAutomaticCapture() {
        // Invalidate the timer to stop writing frames
        self.isFlashVisible = false
        cameraTimer?.invalidate()
    }
}

enum Actions {
    case heartbeat(String)
    case display_box(Bool)
    case set_center([Float])
    case set_angle(Float)
    case set_scale([Float])
    case extend_sides([Float])
    case shrink_sides([Float])
    case raycast_center(CGPoint, ARFrame)
    case set_floor(CGPoint, ARFrame)
//    case get_box_info
}



class ActionManager {
    static let shared = ActionManager()
    
    private init() { }
    
    var actionStream = PassthroughSubject<Actions, Never>()
}
