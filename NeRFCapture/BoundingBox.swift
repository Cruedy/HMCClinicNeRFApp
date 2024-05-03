//
//  BoundingBox.swift
//  NeRFCapture
//
//  Created by Clinic on 11/5/23.
//

import ARKit
import Foundation
import RealityKit
import AVFoundation
import simd

//fileprivate extension ARView.DebugOptions {
//
//    func showCollisions() -> ModelEntity {
//
//        print("Code for visualizing collision objects goes here...")
//
//        let vc = ViewController()
//
//        let box = MeshResource.generateBox(size: 0.04)
//        let color = UIColor(white: 1.0, alpha: 0.15)
//        let colliderMaterial = UnlitMaterial(color: color)
//
//        vc.visualCollider = ModelEntity(mesh: box,
//                                   materials: [colliderMaterial])
//        return vc.visualCollider
//    }
//}

class BoundingBoxPlane {
    var descr: MeshDescriptor
    var index: Int
    var entity: ModelEntity
    
    init(descr: MeshDescriptor, entity: ModelEntity, index: Int) {// width: width, height: height
        self.descr = descr
        self.entity = entity
        self.index = index
    }
    
    
}

class BoundingBox {
    // Properties to store bounding box information
    var center: [Float] = [] // x is left-right, z is forward-back, y is down-up (respective to the neg side-pos side)
    // Coordinate axes in ARKit: https://developer.apple.com/documentation/arkit/arconfiguration/worldalignment/gravity
    var positions: [[Float]] = []
    var rot_y: Float = 0 // in radians
    var scale: [Float] = [1,1,1]
    var entity_anchor: AnchorEntity = AnchorEntity(world:.zero)
    var floor: Float? = nil
    var planes: [BoundingBoxPlane] = []
    var plane_counts = [0,0,0,0,0,0]
    var plane_orientations: [simd_quatf] = [simd_quatf(ix: 0, iy: 0, iz: 1, r: 0), simd_quatf(ix: 0, iy: 0, iz: 1, r: 0), simd_quatf(ix: 0, iy: 0, iz: 1, r: 0), simd_quatf(ix: 0, iy: 0, iz: 1, r: 0), simd_quatf(ix: 0, iy: 0, iz: 1, r: 0), simd_quatf(ix: 0, iy: 0, iz: 1, r: 0)]
    var plane_centers: [SIMD3<Float>] = [SIMD3<Float>(0.0, 0.0, 0.0), SIMD3<Float>(0.0, 0.0, 0.0), SIMD3<Float>(0.0, 0.0, 0.0), SIMD3<Float>(0.0, 0.0, 0.0), SIMD3<Float>(0.0, 0.0, 0.0), SIMD3<Float>(0.0, 0.0, 0.0)]
    var player: AVAudioPlayer?
    private var cameraRaysAndHitLocations: [(ray: Ray, hitLocation: SIMD3<Float>)] = []
    
    // Initialize the bounding box with a center point
    init(center point: [Float]){
        self.center = point
        self.positions = pos_from_center(point)
    }
    
    func print_props() -> Void{
        print("""

BoundingBox:
center: \(center)
positions: \(positions)
rot_y: \(rot_y)
scale: \(scale)

""")
    }
    
    func encode_as_json() -> BoundingBoxManifest
    {
        let bounding_box_center = array_to_XYZ(array: self.center)
        let rad_rot_about_y = rot_y
        let bounding_box_positions = BoundingBoxManifest.Corners(top_left_front: array_to_XYZ(array: self.positions[0]),
                                                                top_right_front: array_to_XYZ(array: self.positions[1]),
                                                                bot_right_front: array_to_XYZ(array: self.positions[2]),
                                                                bot_left_front: array_to_XYZ(array: self.positions[3]),
                                                                top_left_back: array_to_XYZ(array: self.positions[4]),
                                                                top_right_back: array_to_XYZ(array: self.positions[5]),
                                                                bot_right_back: array_to_XYZ(array: self.positions[6]),
                                                                bot_left_back: array_to_XYZ(array: self.positions[7]))
        
        let entity_anchor_4x4 = simd_float4x4_to_array(matrix: entity_anchor.transform.matrix)
        
        let sampleBoundingBox = BoundingBoxManifest(center: bounding_box_center,
                                                    rad_rot_about_y: rad_rot_about_y,
                                                    positions: bounding_box_positions,
                                                    entity_anchor_4x4: entity_anchor_4x4)
        return sampleBoundingBox
    }
    
    func simd_float4x4_to_array(matrix: simd_float4x4) -> [[Float]]
    {
      var array = [[Float]](repeating: [Float](repeating: 0.0, count: 4), count: 4)
      for i in 0..<4 {
        for j in 0..<4 {
          array[i][j] = matrix[i][j]
        }
      }
      return array
    }
    
    func array_to_XYZ(array: [Float]) -> BoundingBoxManifest.XYZ
    {
        return BoundingBoxManifest.XYZ(x:array[0], y:array[1], z:array[2])
    }
    
    
    // Get the position relative to the camera
    func pos_relative_to_camera() -> SIMD3<Float>{
        return entity_anchor.position
    }
    
    // Calculate the rotation about the Y-axis for a given angle and point
    func rot_about_y(angle: Float, point: [Float]) -> simd_float3 {
        let rot_matrix =  simd_float3x3(rows: [simd_float3([cos(angle), 0, sin(angle)]),
                                               simd_float3([0,1,0]),
                                               simd_float3([-sin(angle), 0, cos(angle)])])
        let point_a = simd_float3(point)
        return rot_matrix*point_a
    }
    
    // Calculate positions of the bounding box corners relative to the center
    func pos_from_center(_ point:[Float]) -> [[Float]]{
        // Calculate corner positions based on rotation and scaling
                
        let top_left_front = pairwise_add(simd_float3(point), rot_about_y(angle:rot_y , point: [-1.0*scale[0]/2.0, 1.0*scale[1]/2.0, -1.0*scale[2]/2.0]))
        let top_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, 1*scale[1]/2, -1*scale[2]/2]))
        var bot_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, -1*scale[1]/2, -1*scale[2]/2]))
        var bot_left_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, -1*scale[1]/2, -1*scale[2]/2]))
        let top_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, 1*scale[1]/2, 1*scale[2]/2]))
        let top_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, 1*scale[1]/2, 1*scale[2]/2]))
        var bot_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, -1*scale[1]/2, 1*scale[2]/2]))
        var bot_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, -1*scale[1]/2, 1*scale[2]/2]))
        if let floor = floor{
            bot_right_front[1] = max(bot_right_front[1], floor)
            bot_left_front[1] = max(bot_left_front[1], floor)
            bot_right_back[1] = max(bot_right_back[1], floor)
            bot_left_back[1] = max(bot_left_back[1], floor)
        }
        return [top_left_front, top_right_front, bot_right_front, bot_left_front,
                top_left_back,  top_right_back,  bot_right_back,  bot_left_back]
    }
    
    // Helper function to add two arrays element-wise
    // TODO: switch to using simd throughout
    func pairwise_add(_ a: [Float], _ b: [Float]) -> [Float] {
        assert(a.count == b.count)
        var result: [Float] = []
        for i in 0...a.count-1 {
            result.append(a[i]+b[i])
        }
        return result
    }
    
    func pairwise_add(_ a: simd_float3, _ b: simd_float3) -> [Float] {
        var result: [Float] = []
        for i in 0...3-1 {
            result.append(a[i]+b[i])
        }
        return result
    }
    
    func pairwise_mult(_ a: [Float], _ b: [Float]) -> [Float] {
        assert(a.count == b.count)
        var result: [Float] = []
        for i in 0...a.count-1 {
            result.append(a[i]*b[i])
        }
        return result
    }
    
    // Helper function to create lines
    func createLine(corners: [[Float]], thickness: Float) -> MeshDescriptor{
        var positions: [SIMD3<Float>] = []
        
        var descr = MeshDescriptor(name: "line")

        // Offsets are neccessary because RealityKit can't render 1d objects
        // We go around this problem by changing the object into plane
        // One of the dimensions will still be flat, can fix this by offsetting the z
        for corner in corners {
            positions.append(SIMD3<Float>([corner[0]+thickness, corner[1], corner[2]]))
            positions.append(SIMD3<Float>([corner[0]-thickness, corner[1], corner[2]]))
            positions.append(SIMD3<Float>([corner[0], corner[1]+thickness, corner[2]]))
            positions.append(SIMD3<Float>([corner[0], corner[1]-thickness, corner[2]]))
        }
        descr.positions = MeshBuffers.Positions(positions[0...7])
        
        // We need two rows for each face because the rendering will only display points connected in a counterclockwise orientation relative to the viewing position
        // Here we simply render it both ways.
        descr.primitives = .polygons([4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
                                                         [1, 2, 0, 3,  // front
                                                          3, 0, 2, 1,
                                                          5, 6, 4, 7,  // back
                                                          7, 4, 6, 5,
                                                          2, 0, 4, 6,  // top
                                                          6, 4, 0, 2,
                                                          2, 1, 5, 6,  // bottom
                                                          6, 5, 1, 2,
                                                          0, 3, 7, 4,  // left
                                                          4, 7, 3, 0,
                                                          1, 3, 7, 5,  // right
                                                          5, 7, 3, 1])
        
        return descr
        
    }
    
    // Helper function to create squares in bounding box
    func createSquare(x: Float, y: Float, width: Float, height: Float) -> MeshDescriptor {
        // Your implementation to create a square mesh descriptor
        // This can involve creating vertices and defining edges for the square
        // Return the mesh descriptor for the square
        // Example:
        let squareMeshDescriptor = MeshDescriptor() // Your implementation here
        return squareMeshDescriptor
    }
    
//    def new_position_scalar(P, C, shrink_scalar):
//        direction = C - P
//        norm_direction = direction / np.linalg.norm(direction)  # Normalize the direction vector
//        return P + norm_direction * shrink_scalar  # Move the point towards the centroid

    func calc_centroid(corners: [SIMD3<Float>]) -> SIMD3<Float> {
        // Calculate the sum of all vectors
        let sum = corners.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 }

        // Calculate the average by dividing the sum by the number of vectors
        let average = sum / Float(corners.count)
        
        // Return the calculated average (centroid)
        return average
    }
    
    func shrink_torwards_center(P: SIMD3<Float>, C: SIMD3<Float>, shrinkScalar: Float) -> SIMD3<Float> {
        let direction = C - P
        let norm = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        let normDirection = direction / norm  // Normalize the direction vector
        
        return P + normDirection * shrinkScalar  // Move the point towards the centroid
    }
    
    func createPlaneFromCorners(corners: [[Float]], shrinkScalar: Float) -> MeshDescriptor {
        var positions: [SIMD3<Float>] = []
        
        // Offsets are necessary because RealityKit can't render 1D objects
        // We go around this problem by changing the object into a plane
        // One of the dimensions will still be flat, can fix this by offsetting the z
        
        for corner in corners {
            positions.append(SIMD3<Float>(corner[0]-0.001, corner[1]+0.001, corner[2]+0.001))
        }
        
        let centroid = calc_centroid(corners: positions)
        
        // loop through positions, call shrink_towards_center for each position and replace the position at each index with the result
        for i in 0..<positions.count {
                positions[i] = shrink_torwards_center(P: positions[i], C: centroid, shrinkScalar: shrinkScalar)
            }
        
        var planeDescr = MeshDescriptor(name: "plane")
        planeDescr.positions = MeshBuffers.Positions(positions)
        
        planeDescr.primitives = .polygons([4, 4], [0, 1, 2, 3, 3, 2, 1, 0])
        // Define indices to create two triangles for the plane
//        let indices: [UInt32] = [0, 1, 2, 2, 3, 0, 2, 1, 0, 0, 3, 2]
//        planeDescr.primitives = .triangles(indices)
        
        return planeDescr
    }
    
    func getOrientation(from points: [SIMD3<Float>]) -> simd_quatf {
        let A = points[0]
        let B = points[1]
        let C = points[2]
        
        var x = normalize(B - A)
        let tmp = C - A
        
        var z = cross(x, tmp)
        z = normalize(z)
        var y = cross(z, x)
        y = normalize(y)
        
        let rotationMatrix = simd_float3x3(columns: (x, y, z))
        return simd_quatf(rotationMatrix)
    }
    
    // Helper function to create bounding box lines
    func createBoundingBox(corners: [[Float]], thickness: Float) -> ([MeshDescriptor], [MeshDescriptor]) {
        
        var line_descrs: [MeshDescriptor] = []
//        var plane_descrs: [MeshDescriptor] = []
        
        // TODO: This can be a bit confusing. Maybe create a struct for just the corners
        let top_left_front = corners[0]
        let top_right_front = corners[1]
        let bottom_right_front = corners[2]
        let bottom_left_front = corners[3]
        let top_left_back = corners[4]
        let top_right_back = corners[5]
        let bottom_right_back = corners[6]
        let bottom_left_back = corners[7]
        
        // Add orientation of each face
        // front face
        self.plane_orientations[0] = getOrientation(from : [SIMD3<Float>(bottom_right_front), SIMD3<Float>(bottom_left_front), SIMD3<Float>(top_right_front)])
        // left face
        self.plane_orientations[1] = getOrientation(from : [SIMD3<Float>(bottom_left_front), SIMD3<Float>(bottom_left_back), SIMD3<Float>(top_left_back)])
        // right face
        self.plane_orientations[2] = getOrientation(from : [SIMD3<Float>(bottom_right_back), SIMD3<Float>(bottom_right_front), SIMD3<Float>(top_right_front)])
        // bottom face
        self.plane_orientations[3] = getOrientation(from : [SIMD3<Float>(bottom_left_front), SIMD3<Float>(bottom_right_front), SIMD3<Float>(bottom_left_back)])
        // top face
        self.plane_orientations[4] = getOrientation(from : [SIMD3<Float>(top_right_front), SIMD3<Float>(top_left_front), SIMD3<Float>(top_right_back)])
        // back face
        self.plane_orientations[5] = getOrientation(from : [SIMD3<Float>(bottom_left_back), SIMD3<Float>(bottom_right_back), SIMD3<Float>(top_left_back)])
        
        
        // Add centers of each face
        // front face
        self.plane_centers[0] = SIMD3<Float>((top_left_front[0] + top_right_front[0])/2.0, (top_left_front[1] + bottom_left_front[1])/2.0, (top_left_front[2] + top_right_front[2])/2.0)
        // left face
        self.plane_centers[1] = SIMD3<Float>((top_left_front[0] + top_left_back[0])/2.0, (top_left_back[1] + bottom_left_back[1])/2.0, (bottom_left_front[2] + bottom_left_back[2])/2.0)
        // right face
        self.plane_centers[2] = SIMD3<Float>((top_right_front[0] + top_right_back[0])/2.0, (bottom_right_front[1] + top_right_front[1])/2.0, (bottom_right_front[2] + bottom_right_back[2])/2.0)
        // bottom face
        self.plane_centers[3] = SIMD3<Float>((bottom_left_front[0] + bottom_right_back[0])/2.0, (bottom_right_front[1] + bottom_left_back[1])/2.0, (bottom_left_front[2] + bottom_right_back[2])/2.0)
        // top face
        self.plane_centers[4] = SIMD3<Float>((top_left_back[0] + top_right_front[0])/2.0, (top_right_back[1] + top_left_front[1])/2.0, (top_left_front[2] + top_right_back[2])/2.0)
        // back face
        self.plane_centers[5] = SIMD3<Float>((top_left_back[0] + top_right_back[0])/2.0, (top_left_back[1] + bottom_left_back[1])/2.0, (top_left_back[2] + top_right_back[2])/2.0)
        
        // Connect all the points to create a hollow box, the bounding box
        line_descrs.append(createLine(corners: [top_left_front, top_right_front], thickness: thickness))
        line_descrs.append(createLine(corners: [bottom_left_front, bottom_right_front], thickness: thickness))
        line_descrs.append(createLine(corners: [top_left_front, bottom_left_front], thickness: thickness))
        line_descrs.append(createLine(corners: [top_right_front, bottom_right_front], thickness: thickness))
        
        line_descrs.append(createLine(corners: [top_left_back, top_right_back], thickness: thickness))
        line_descrs.append(createLine(corners: [bottom_left_back, bottom_right_back], thickness: thickness))
        line_descrs.append(createLine(corners: [top_left_back, bottom_left_back], thickness: thickness))
        line_descrs.append(createLine(corners: [top_right_back, bottom_right_back], thickness: thickness))

        line_descrs.append(createLine(corners: [top_left_back, top_left_front], thickness: thickness))
        line_descrs.append(createLine(corners: [bottom_left_back, bottom_left_front], thickness: thickness))
        line_descrs.append(createLine(corners: [top_right_front, top_right_back], thickness: thickness))
        line_descrs.append(createLine(corners: [bottom_right_front, bottom_right_back], thickness: thickness))
        
        planes = []
        // start by creating the front face of the bounding box
        var plane_descrs = [createPlaneFromCorners(corners: [top_left_front, top_right_front, bottom_right_front, bottom_left_front], shrinkScalar: thickness*1.5)]
        // Adding left face of bounding box
        plane_descrs.append(createPlaneFromCorners(corners: [top_left_front, bottom_left_front, bottom_left_back, top_left_back], shrinkScalar: thickness*1.5))
        // Adding right face of bounding box
        plane_descrs.append(createPlaneFromCorners(corners: [top_right_front, bottom_right_front, bottom_right_back, top_right_back], shrinkScalar: thickness*1.5))
        // Adding bottom of bounding box
        plane_descrs.append(createPlaneFromCorners(corners: [bottom_right_front, bottom_left_front, bottom_left_back, bottom_right_back], shrinkScalar: thickness*1.5))
        // Adding top of bounding box
        plane_descrs.append(createPlaneFromCorners(corners: [top_left_front, top_left_back, top_right_back, top_right_front], shrinkScalar: thickness*1.5))
        // Adding back of bounding
        plane_descrs.append(createPlaneFromCorners(corners: [top_left_back, top_right_back, bottom_right_back, bottom_left_back], shrinkScalar: thickness*1.5))
        
        return (line_descrs, plane_descrs)
    }
    
    func playFinishedSound() {
        print("tryingSound")
        print(Bundle.main.url(forResource: "Disappear", withExtension: "mp3"))
        guard let url = Bundle.main.url(forResource: "Sparkle", withExtension: "mov") else { return }
        print("pastUrl")
        print(url)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func textGen(textString: String) -> ModelEntity {
        let materialVar = SimpleMaterial(color: .white, roughness: 0, isMetallic: false)
        
        let depthVar: Float = 0.001
        let fontVar = UIFont.systemFont(ofSize: 0.01)
        let containerFrameVar = CGRect(x: -0.05, y: -0.1, width: 0.1, height: 0.1)
        let alignmentVar: CTTextAlignment = .center
        let lineBreakModeVar : CTLineBreakMode = .byWordWrapping
        
        let textMeshResource : MeshResource = .generateText(textString,
                                           extrusionDepth: depthVar,
                                           font: fontVar,
                                           containerFrame: containerFrameVar,
                                           alignment: alignmentVar,
                                           lineBreakMode: lineBreakModeVar)
        
        let textEntity = ModelEntity(mesh: textMeshResource, materials: [materialVar])
        
        return textEntity
    }
    // Add a new bounding box to the scene
    func addNewBoxToScene() -> AnchorEntity{
        let worldOriginAnchor = AnchorEntity(world:.zero)
//        let worldOriginAnchor = AnchorEntity(plane:.horizontal) // This is for letting the object move on the ground
        self.positions = self.pos_from_center(self.center)
        let descriptors = createBoundingBox(corners: self.positions, thickness: 0.001)
        for descr in descriptors.0 {
            let material = UnlitMaterial(color: .purple)
            
            let generatedModel = ModelEntity(
               mesh: try! .generate(from: [descr]),
               materials: [material]
            )
            
            worldOriginAnchor.addChild(generatedModel)
        }
        var i = 0
        let goal = 10.0
        var entityList: [ModelEntity] = []
        for descr in descriptors.1 {
            var material: UnlitMaterial
            let progress = Float(plane_counts[i]) / Float(goal)
            // Define colors using SIMD3<Float>
            // rgb for yellow
            let rgb = SIMD3<Float>(1, 1, 0)
            // rgb for green
            let final_rgb = SIMD3<Float>(0, 1, 1)
            var opacity = Float(0.0)
            if progress < 1.0{
                opacity = 0.25 + (progress * 0.5)
            } 
            else if progress == 1.0{
                playFinishedSound()
                opacity = 0.0
            }
            // Interpolate between red and blue
            let new_rgb = (progress * final_rgb) + ((1.0 - progress) * rgb)

            // Assuming you want to use the interpolated values directly for UIColor
            let color = UIColor(red: CGFloat(new_rgb.x), green: CGFloat(new_rgb.y), blue: CGFloat(new_rgb.z), alpha: CGFloat(opacity))
            material = UnlitMaterial(color: color)
            let generatedModel = ModelEntity(
                mesh: try! .generate(from: [descr]),
                materials: [material])
            generatedModel.generateCollisionShapes(recursive: true)
//            if progress == 1.0 {
//                let generatedText = textGen(textString: "side completed")
//                generatedModel.addChild(generatedText)
//                generatedText.position = self.plane_centers[i]
//                generatedText.orientation = plane_orientations[i]
//            }
            worldOriginAnchor.addChild(generatedModel)
            var newPlane = BoundingBoxPlane(descr: descr, entity: generatedModel, index: i)
            i = i+1
            planes.append(newPlane)
        }
        self.entity_anchor = worldOriginAnchor
        return worldOriginAnchor
    }
    
    func contains(_ pointInWorld: SIMD3<Float>, corners:[[Float]]) -> Bool {
        // Calculate the minimum and maximum local coordinates of the bounding box
        var localMin = SIMD3<Float>(x: Float.greatestFiniteMagnitude, y: Float.greatestFiniteMagnitude, z: Float.greatestFiniteMagnitude)
        var localMax = SIMD3<Float>(x: -Float.greatestFiniteMagnitude, y: -Float.greatestFiniteMagnitude, z: -Float.greatestFiniteMagnitude)

        // Find the minimum and maximum coordinates of the bounding box's corners
        for corner in corners {
            localMin.x = min(localMin.x, corner[0])
            localMin.y = min(localMin.y, corner[1])
            localMin.z = min(localMin.z, corner[2])
            
            localMax.x = max(localMax.x, corner[0])
            localMax.y = max(localMax.y, corner[1])
            localMax.z = max(localMax.z, corner[2])
        }

        // Check if the given point lies within the bounding box along all three axes
        return (localMin.x...localMax.x).contains(pointInWorld.x) &&
               (localMin.y...localMax.y).contains(pointInWorld.y) &&
               (localMin.z...localMax.z).contains(pointInWorld.z)
    }
    
    // update properties using some kind of offset
    func update_center(_ offset:[Float]) -> [Float] {
        center = pairwise_add(center, offset)
        return center
    }
    
    func update_scale(_ scale_mult:[Float]) -> [Float] {
        scale = pairwise_mult(scale, scale_mult)
        if let floor=floor {
            center[1] = scale[1]/2 + floor
        }
        return scale
    }
    
    func update_angle(_ offset: Float) -> Float {
        rot_y += offset
        return rot_y
    }
    
    // set properties to new values
    func set_center(_ new_center:[Float]) -> [Float]{
        center = new_center
        return center
    }
    
    func set_scale(_ new_scale:[Float]) -> [Float]{
        scale = new_scale
        if let floor=floor {
            center[1] = scale[1]/2 + floor
        }
        return scale
    }
    
    func set_angle(_ new_angle: Float) -> Float {
        rot_y = new_angle
        return rot_y
    }
    
    // Extend and shrink sides
    func extend_side(_ offset: [Float]) -> ([Float], [Float]){
        scale = pairwise_add(scale, [abs(offset[0]), abs(offset[1]), abs(offset[2])])
        let new_center = pairwise_add(simd_float3(center), rot_about_y(angle: rot_y, point: [offset[0]/2,offset[1]/2, offset[2]/2]))
        center = [new_center[0], new_center[1], new_center[2]] // change from simd to float
        positions = pos_from_center(center)
        return (center, scale)
    }
    
    func shrink_side(_ offset: [Float]) -> ([Float], [Float]) {
        scale = pairwise_add(scale, [-1*abs(offset[0]), -1*abs(offset[1]), -1*abs(offset[2])])
        let new_center = pairwise_add(simd_float3(center), rot_about_y(angle: rot_y, point: [offset[0]/2,offset[1]/2, offset[2]/2]))
        center = [new_center[0], new_center[1], new_center[2]] // change from simd to float
        positions = pos_from_center(center)
        return (center, scale)
    }
    
    func set_center_xz(newCenter: SIMD3<Float>) -> [Float]
    {
        let y_center: Float
        if let floor = floor {
            y_center = scale[1]/2 + floor
        } else {
            y_center = newCenter[1]
        }
        center = [newCenter[0], y_center, newCenter[2]]
        return center;
    }

    func setFloor(height:Float){
        floor = height
    }
    
}
