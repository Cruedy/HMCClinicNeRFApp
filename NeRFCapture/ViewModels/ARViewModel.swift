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
import CoreLocation
import os.log
enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

@available(iOS 17.0, *)
class ARViewModel : NSObject, ARSessionDelegate, ObservableObject, CLLocationManagerDelegate {
    @Published var appState = AppState()
    @Published var isFlashVisible = false
    @Published var velocity = Float(0)
    @Published var xList = [Float]()
    @Published var yList = [Float]()
    @Published var zList = [Float]()
    @Published var userVelWarning = ""
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
    var locationTimer: Timer?
    var velocityTimer: Timer?
    var interval: TimeInterval = 3.0
    
    
    init(datasetWriter: DatasetWriter, ddsWriter: DDSWriter) {
        self.datasetWriter = datasetWriter
        self.ddsWriter = ddsWriter
        super.init()
//        self.subscribeToActionStream()
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
        let angle = boundingbox.set_angle(new_angle/180*3.1415926)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return new_angle
    }
    
    func set_scale(new_scale: [Float]) -> [Float] {
        let scale = boundingbox.set_scale(new_scale)
        display_box(boxVisible: boxVisible)
        update_boundingbox_manifest()
        return scale
    }
    
    func extend_sides(offset: [Float]) -> ([Float], [Float]){
        let (center, scale) = boundingbox.extend_side(offset)
        update_boundingbox_manifest()
        return (center, scale)
    }
    
    func shrink_sides(offset: [Float]) -> ([Float], [Float]){
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
    
    private func side() -> (side: BoundingBoxPlane?, hitLocation: SIMD3<Float>)? {
        guard let arView = arView else {
            print("arView is nil")
            return (side: nil, hitLocation: SIMD3<Float>(boundingbox.center))
        }
//        guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return (side: nil, hitLocation: SIMD3<Float>(boundingbox.center)) }
//        let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
//        let cameraForward = SIMD3<Float>(-cameraTransform.columns.2.x, -cameraTransform.columns.2.y, -cameraTransform.columns.2.z)
        let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
//        let planeSize = CGSize(width: <#T##CGFloat#>, height: <#T##CGFloat#>)
//        let planeRect = CGRect(origin: screenCenter, size: planeSize)
        
        let collisionResult = arView.hitTest(screenCenter)
        print("collisionresult")
        print(collisionResult)
        
        // Perform hit test with given ray
//        let raycastResults = arView.raycast(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
        
        // We cannot just look at the first result because we might have hits with other than the tile geometries.
        if let firstResult = collisionResult.first {
            print("firstResult")
            print(firstResult)
            // Assuming you have a way to access your planes
            // You'll need to identify which plane was hit and change its color
            for plane in boundingbox.planes {
                print("current plane")
                print(plane.entity)
                if plane.entity == firstResult.entity {
                    print("True")
                    // Change the color of the hit plane
                    let lessTransparentYellowColor = UIColor.yellow.withAlphaComponent(0.75)
                    let newMaterial = UnlitMaterial(color: lessTransparentYellowColor)
                    plane.entity.model?.materials = [newMaterial]
                    print("checkCounts")
                    print(plane.index)
                    print(boundingbox.plane_counts[plane.index])
                    boundingbox.plane_counts[plane.index]  = boundingbox.plane_counts[plane.index]+1
                    print("counts: \(boundingbox.plane_counts)")
                    break
                }
            }
        }
//        for result in raycastResults {
//            print("result")
//            print(result)
//            print("---------")
////            if let tile = result.node as? BoundingBoxPlane, side.isBusyUpdatingTiles {
////                // Each ray should only hit one tile, so we can stop iterating through results if a hit was successful.
////                return (side: side, hitLocation: SIMD3<Float>(result.worldCoordinates))
////            }
//        }
        return nil
    }
    
    func rayCast_changeBoundingColor(at screenPoint: CGPoint, frame: ARFrame){
        
    }
    
    func findFloorHeight(at screenPoint: CGPoint, frame: ARFrame){
        
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
        let boundingBoxManifest = boundingbox.encode_as_json()
        datasetWriter.boundingBoxManifest = boundingBoxManifest
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
        // Schedule a new timer to call writeFrameToDisk every 3 seconds
        cameraTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(changeInterval),userInfo: nil, repeats: true)
    }
    
    @objc func changeInterval() {
        if let frame = self.session?.currentFrame {
            // call raycast function here
            self.datasetWriter.writeFrameToDisk(frame: frame)
            self.side()
            // Trigger the flash effect
            self.isFlashVisible = true
            // Hide flash after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isFlashVisible = false
            }
            if velocity >= 8 && velocity < 10 {
                print("Interval 1.0")
                interval = 1.0
                startAutomaticCapture()
            }
            else if velocity >= 5 && velocity < 8 {
                print("Interval 2.0")
                interval = 2.0
                startAutomaticCapture()
            }
            else if velocity < 5 {
                print("Interval 3.0")
                interval = 3.0
                startAutomaticCapture()
            }
        }
        
    }
    
    func stopAutomaticCapture() {
        // Invalidate the timer to stop writing frames
        self.isFlashVisible = false
        cameraTimer?.invalidate()
//        motionManager.stopAccelerometerUpdates()
    }
    
    func applyFilter(_ inputTransform: simd_float4x4) -> simd_float4x4 {
        let alpha: Float = 0.2 // Adjust this value to control the level of smoothing
        // Assuming you are using a simple averaging technique for filtering
        if let previousTransform = arView?.session.currentFrame?.camera.transform {
            var filteredTransform = simd_float4x4()
            for i in 0..<4 {
                for j in 0..<4 {
                    filteredTransform[i][j] = previousTransform[i][j] + alpha * (inputTransform[i][j] - previousTransform[i][j])
                }
            }
            return filteredTransform
        } else {
            // If there is no previous transform, return the input transform
            return inputTransform
        }
    }
    
    func trackVelocity() {
        velocityTimer?.invalidate()
        velocityTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if let transform = self.arView?.session.currentFrame?.camera.transform {
                let filteredTransform = self.applyFilter(transform)
                let position = filteredTransform.columns.3
                // units are in meters
                let positionVector = SIMD3<Float>(position.x, position.y, position.z)
                let positionInInches = SIMD3<Float>(positionVector.x * 39.37, positionVector.y * 39.37, positionVector.z * 39.37)
                if !self.xList.isEmpty {
                    let xDifference = abs(self.xList.last! - positionInInches.x)
                    let yDifference = abs(self.yList.last! - positionInInches.y)
                    let zDifference = abs(self.zList.last! - positionInInches.z)
                    let xVel = xDifference/0.5
                    let yVel = yDifference/0.5
                    let zVel = zDifference/0.5
                    let velMag = sqrt(xVel * xVel + yVel * yVel + zVel * zVel)
                    if velMag > 10 {
                        self.userVelWarning = "Slow Down"
                    }
                    else if velMag < 5 {
                        self.userVelWarning = "Speed Up"
                    }
                    else {
                        self.userVelWarning = "Try to keep this speed between 5 and 10"
                    }
                    self.xList.append(positionInInches.x)
                    self.yList.append(positionInInches.y)
                    self.zList.append(positionInInches.z)
                    self.velocity = velMag
                } else {
                    self.xList.append(positionInInches.x)
                    self.yList.append(positionInInches.y)
                    self.zList.append(positionInInches.z)
                    self.velocity = 0.0
                }
            }
        }
    }
    
    func stopTrackingLocation(){
        locationTimer?.invalidate()
    }
    
    func stopTrackingVelocity(){
        velocityTimer?.invalidate()
    }
}

//enum Actions {
//    case heartbeat(String)
//    case display_box(Bool)
//    case set_center([Float])
//    case set_angle(Float)
//    case set_scale([Float])
//    case extend_sides([Float])
//    case shrink_sides([Float])
//    case raycast_center(CGPoint, ARFrame)
//    case set_floor(CGPoint, ARFrame)
////    case get_box_info
//}


//
//class ActionManager {
//    static let shared = ActionManager()
//    
//    private init() { }
//    
//    var actionStream = PassthroughSubject<Actions, Never>()
//}
