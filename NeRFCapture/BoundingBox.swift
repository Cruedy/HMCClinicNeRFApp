//
//  BoundingBox.swift
//  NeRFCapture
//
//  Created by Clinic on 11/5/23.
//

import ARKit
import Foundation
import RealityKit

class BoundingBox {
    // Properties to store bounding box information
    var center: [Float] = [] // x is left-right, z is forward-back, y is down-up (respective to the neg side-pos side)
    // Coordinate axes in ARKit: https://developer.apple.com/documentation/arkit/arconfiguration/worldalignment/gravity
    var positions: [[Float]] = []
    var rot_y: Float = 0 // in radians
    var scale: [Float] = [1,1,1]
    var entity_anchor: AnchorEntity = AnchorEntity(world:.zero)

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
        
        var top_left_front = pairwise_add(simd_float3(point), rot_about_y(angle:rot_y , point: [-1.0*scale[0]/2.0, 1.0*scale[1]/2.0, -1.0*scale[2]/2.0]))
        var top_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, 1*scale[1]/2, -1*scale[2]/2]))
        var bot_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, -1*scale[1]/2, -1*scale[2]/2]))
        var bot_left_front = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, -1*scale[1]/2, -1*scale[2]/2]))
        var top_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, 1*scale[1]/2, 1*scale[2]/2]))
        var top_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, 1*scale[1]/2, 1*scale[2]/2]))
        var bot_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [1*scale[0]/2, -1*scale[1]/2, 1*scale[2]/2]))
        var bot_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: rot_y, point: [-1*scale[0]/2, -1*scale[1]/2, 1*scale[2]/2]))
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
    
    // Helper function to create bounding box lines
    func createBoundingBox(corners: [[Float]], thickness: Float) -> [MeshDescriptor] {
        
        var line_descrs: [MeshDescriptor] = []
        
        // TODO: This can be a bit confusing. Maybe create a struct for just the corners
        let top_left_front = corners[0]
        let top_right_front = corners[1]
        let bottom_right_front = corners[2]
        let bottom_left_front = corners[3]
        let top_left_back = corners[4]
        let top_right_back = corners[5]
        let bottom_right_back = corners[6]
        let bottom_left_back = corners[7]
        
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


        return line_descrs
    }
    
    // Add a new bounding box to the scene
    func addNewBoxToScene() -> AnchorEntity{
        let worldOriginAnchor = AnchorEntity(world:.zero)
//        let worldOriginAnchor = AnchorEntity(plane:.horizontal) // This is for letting the object move on the ground
        self.positions = self.pos_from_center(self.center)
        var descrs = createBoundingBox(corners: self.positions, thickness: 0.01)
        for descr in descrs {
            let material = UnlitMaterial(color: .orange)
            
            let generatedModel = ModelEntity(
               mesh: try! .generate(from: [descr]),
               materials: [material]
            )
            
            worldOriginAnchor.addChild(generatedModel)
        }
        self.entity_anchor = worldOriginAnchor
        return worldOriginAnchor
    }
    
    // update properties using some kind of offset
    func update_center(_ offset:[Float]) {
        self.center = pairwise_add(self.center, offset)
    }
    
    func update_scale(_ scale_mult:[Float]) {
        self.scale = pairwise_mult(self.scale, scale_mult)
    }
    
    func update_angle(_ offset: Float) {
        self.rot_y += offset
    }
    
    // set properties to new values
    func set_center(_ new_center:[Float]) {
        self.center = new_center
    }
    
    func set_scale(_ new_scale:[Float]) {
        self.scale = new_scale
    }
    func set_angle(_ new_angle: Float) {
        self.rot_y = new_angle
    }
    
    
    // Extend and shrink sides
    func extend_side(_ offset: [Float]){
        scale = pairwise_add(scale, [abs(offset[0]), abs(offset[1]), abs(offset[2])])
        let new_center = pairwise_add(simd_float3(center), rot_about_y(angle: rot_y, point: [offset[0]/2,offset[1]/2, offset[2]/2]))
        center = [new_center[0], new_center[1], new_center[2]] // change from simd to float
        positions = pos_from_center(center)
        
    }
    func shrink_side(_ offset: [Float]){
        scale = pairwise_add(scale, [-1*abs(offset[0]), -1*abs(offset[1]), -1*abs(offset[2])])
        let new_center = pairwise_add(simd_float3(center), rot_about_y(angle: rot_y, point: [offset[0]/2,offset[1]/2, offset[2]/2]))
        center = [new_center[0], new_center[1], new_center[2]] // change from simd to float
        positions = pos_from_center(center)
    }
    
    
    func updateBoundingBoxUsingPointCloud(frame: ARFrame, focusPoint: SIMD3<Float>) {
        if let (plc_size, plc_center) = wrapPointCloud(frame: frame, focusPoint: focusPoint){
            center = [plc_center[0], plc_center[1], plc_center[2]]
            scale = [plc_size[0], plc_size[1], plc_size[2]]
            positions = pos_from_center(center)
        } else {
            print("Couldn't use point cloud.")
        }
    }

    func wrapPointCloud(frame: ARFrame, focusPoint: SIMD3<Float>) -> (size: SIMD3<Float>, center: SIMD3<Float>)? {
        // Extract the ARPointCloud from the current frame.
        let pointCloud = frame.rawFeaturePoints

        // Create an empty array to store filtered points.
        var filteredPoints: [SIMD3<Float>] = []

        for point in pointCloud!.points {
            // Customize your filtering criteria here.
            // For example, you can skip points that are too far or filter outliers.

            // Skip points that are too far from the device (adjust the threshold as needed).
            let maxDistanceToCamera: Float = 5
            if length(point - focusPoint) > maxDistanceToCamera {
                continue
            }

            // Add the point to the filtered points array.
            filteredPoints.append(point)
        }

        // Check if there are filtered points.
        guard !filteredPoints.isEmpty else {
            print("No filtered points found.")
            return nil
        }

        // Calculate the minimum (`localMin`) and maximum (`localMax`) corners of the bounding box.
        var localMin = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var localMax = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)

        for point in filteredPoints {
            localMin = min(localMin, point)
            localMax = max(localMax, point)
        }

        // Calculate the size and center of the bounding box.
//        let plc_size = localMax - localMin
//        let plc_center = (localMax + localMin) / 2
//
//        print("Filtered points count: \(filteredPoints.count)")
//        print("Bounding box size: \(plc_size)")
//        print("Bounding box center: \(plc_center)")

        
        let plc_center = focusPoint
        let plc_size = SIMD3<Float>(scale)
        return (plc_size, plc_center)
    }


}
