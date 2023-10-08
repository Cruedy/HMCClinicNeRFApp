//// Created by Florian Schweizer on 21.05.22
//
//import ARKit
//import SwiftUI
//import RealityKit
//
//class CustomARView: ARView {
//    required init(frame frameRect: CGRect) {
//        super.init(frame: frameRect)
//    }
//    
//    dynamic required init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // This is the init that we will actually use
//    convenience init() {
//        self.init(frame: UIScreen.main.bounds)
//        
//        placeBlueBlock()
//    }
//    
//    func configurationExamples() {
//        // Tracks the device relative to it's environment
//        let configuration = ARWorldTrackingConfiguration()
//        session.run(configuration)
//        
//        // Not supported in all regions, tracks w.r.t. global coordinates
//        let _ = ARGeoTrackingConfiguration()
//        
//        // Tracks faces in the scene
//        let _ = ARFaceTrackingConfiguration()
//        
//        // Tracks bodies in the scene
//        let _ = ARBodyTrackingConfiguration()
//    }
//    
//    func anchorExamples() {
//        // Attach anchors at specific coordinates in the iPhone-centered coordinate system
//        let coordinateAnchor = AnchorEntity(world: .zero)
//        
//        // Attach anchors to detected planes (this works best on devices with a LIDAR sensor)
//        let _ = AnchorEntity(plane: .horizontal)
//        let _ = AnchorEntity(plane: .vertical)
//        
//        // Attach anchors to tracked body parts, such as the face
//        let _ = AnchorEntity(.face)
//        
//        // Attach anchors to tracked images, such as markers or visual codes
//        let _ = AnchorEntity(.image(group: "group", name: "name"))
//        
//        // Add an anchor to the scene
//        scene.addAnchor(coordinateAnchor)
//    }
//    
//    func entityExamples() {
//        // Load an entity from a usdz file
//        let _ = try? Entity.load(named: "usdzFileName")
//        
//        // Load an entity from a reality file
//        let _ = try? Entity.load(named: "realityFileName")
//        
//        // Generate an entity with code
//        let box = MeshResource.generateBox(size: 1)
//        let entity = ModelEntity(mesh: box)
//        
//        // Add entity to an anchor, so it's placed in the scene
//        let anchor = AnchorEntity()
//        anchor.addChild(entity)
//    }
//    
//    func placeBlueBlock() {
//        let block = MeshResource.generateBox(size: 1)
//        let material = SimpleMaterial(color: .blue, isMetallic: false)
//        let entity = ModelEntity(mesh: block, materials: [material])
//        
//        let anchor = AnchorEntity(plane: .horizontal)
//        anchor.addChild(entity)
//        
//        scene.addAnchor(anchor)
//    }
//}
//
