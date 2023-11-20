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
    var center: [Float] = []
    var positions: [[Float]] = []
    var rot_y: Float = 0 // in radians
    var scale: [Float] = [1,1,1]
    var entity_anchor: AnchorEntity = AnchorEntity(world:.zero)
        
//        [[-0.5, 0.5, -2], [0.5, 0.5, -2], [0.5, -0.5, -2], [-0.5, -0.5, -2],
//                             [-0.5, 0.5, -3], [0.5, 0.5, -3], [0.5, -0.5, -3], [-0.5, -0.5, -3]]
    
    init(center point: [Float]){
        self.center = point
        self.positions = pos_from_center(point)
    }
    
    func pos_relative_to_camera() -> SIMD3<Float>{
        return entity_anchor.position
    }
    
    func rot_about_y(angle: Float, point: [Float]) -> simd_float3 {
        let rot_matrix =  simd_float3x3(rows: [simd_float3([cos(angle), 0, sin(angle)]),
                                               simd_float3([0,1,0]),
                                               simd_float3([-sin(angle), 0, cos(angle)])])
        let point_a = simd_float3(point)
        return rot_matrix*point_a
    }
    
    func pos_from_center(_ point:[Float]) -> [[Float]]{
        var top_left_front = pairwise_add(simd_float3(point), rot_about_y(angle:self.rot_y , point: [-1*scale[0], 1*scale[1], -1*scale[2]]))
        var top_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [1*scale[0], 1*scale[1], -1*scale[2]]))
        var bot_right_front = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [1*scale[0], -1*scale[1], -1*scale[2]]))
        var bot_left_front = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [-1*scale[0], -1*scale[1], -1*scale[2]]))
        var top_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [-1*scale[0], 1*scale[1], 1*scale[2]]))
        var top_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [1*scale[0], 1*scale[1], 1*scale[2]]))
        var bot_right_back = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [1*scale[0], -1*scale[1], 1*scale[2]]))
        var bot_left_back = pairwise_add(simd_float3(point), rot_about_y(angle: self.rot_y, point: [-1*scale[0], -1*scale[1], 1*scale[2]]))
        return [top_left_front, top_right_front, bot_right_front, bot_left_front,
                top_left_back,  top_right_back,  bot_right_back,  bot_left_back]
    }
    
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
        descr.primitives = .polygons([4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4], [1, 2, 0, 3,  // front
                                                          3, 0, 2, 1,
                                                          5, 6, 4, 7,  // back
                                                          7, 4, 6 , 5,
                                                          2, 0, 4, 6,  // top
                                                          6, 4, 0, 2,
                                                          2, 1, 5, 6,  // bottom
                                                          6, 5, 1, 2,
                                                          0, 3, 7, 4,  // left
                                                          4, 7, 3, 0,
                                                          1, 3, 7, 5,
                                                         5, 7, 3, 1]) // right
        
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
        let top_left_front = corners[0]
        let top_right_front = corners[1]
        let bottom_right_front = corners[2]
        let bottom_left_front = corners[3]
        let top_left_back = corners[4]
        let top_right_back = corners[5]
        let bottom_right_back = corners[6]
        let bottom_left_back = corners[7]
        
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
    
    func addNewBoxToScene() -> AnchorEntity{
//        guard let arView = arView else { return AnchorEntity(world: [0, 2, -1])}
//        let worldOriginAnchor = AnchorEntity(world:.zero)
        let worldOriginAnchor = AnchorEntity(plane:.horizontal)
        self.positions = self.pos_from_center(self.center)
        var descrs = createBoundingBox(corners: self.positions, thickness: 0.01)
        for descr in descrs {
//            let material = SimpleMaterial(color: .orange, isMetallic: false)
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
    
    func update_center(_ offset:[Float]) {
        self.center = pairwise_add(self.center, offset)
    }
    
    func update_scale(_ scale_mult:[Float]) {
        self.scale = pairwise_mult(self.scale, scale_mult)
    }
        
    func set_scale(_ new_scale:[Float]) {
        self.scale = new_scale
    }
    func set_angle(_ new_angle: Float) {
        self.rot_y = new_angle
    }
    func set_center(_ new_center:[Float]) {
        self.center = new_center
    }
    
    func update_angle(_ offset: Float) {
        self.rot_y += offset
    }
    
}
