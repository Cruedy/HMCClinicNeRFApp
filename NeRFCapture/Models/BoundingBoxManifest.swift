//
//  BoundingBoxManifest.swift
//  NeRFCapture
//
//  Created by Clinic on 1/25/24.
//

import Foundation
struct BoundingBoxManifest : Codable {
    struct XYZ : Codable {
        let x: Float
        let y: Float
        let z: Float
    }
    struct Corners: Codable {
        let top_left_front: XYZ
        let top_right_front: XYZ
        let bot_right_front: XYZ
        let bot_left_front: XYZ
        let top_left_back: XYZ
        let top_right_back: XYZ
        let bot_right_back: XYZ
        let bot_left_back: XYZ

    }
    var center: XYZ
    var rad_rot_about_y: Float
    var positions: Corners
    var entity_anchor_4x4: [[Float]]
}
