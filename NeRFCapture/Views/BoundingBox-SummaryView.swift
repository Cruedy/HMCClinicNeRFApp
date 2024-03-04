//
//  BoundingBoxSM-SummaryView.swift
//  NeRFCapture
//
//  Created by Clinic on 2/18/24.
//

import Foundation
import SwiftUI
import ARKit

@available(iOS 17.0, *)
struct BoxSummaryView : View {
    @Binding var bbox_placement_states: BoundingBoxPlacementStates
    @Binding var place_box_mode: MovementModes
    @ObservedObject var viewModel: ARViewModel
    
    // controls the bounding box
    @Binding public var boxVisible: Bool
    @Binding public var box_center: [Float]
    @Binding public var rotate_angle: Float
    @Binding public var slider_xyz: [Float]
    
    init( vm: ARViewModel, states: Binding<BoundingBoxPlacementStates>, place_box_mode: Binding<MovementModes>,
          boxVisible: Binding<Bool>, box_center: Binding<[Float]>, rotate_angle: Binding<Float>, slider_xyz: Binding<[Float]>){
        viewModel = vm
        _bbox_placement_states = states
        _place_box_mode = place_box_mode
        _boxVisible = boxVisible
        _box_center = box_center
        _rotate_angle = rotate_angle
        _slider_xyz = slider_xyz
    }
    
    var body: some View {
            VStack {
                Text("Bounding Box Summary")
                    .font(.title)
                    .padding()

                HStack {
                    Text("Visibility:")
                    Spacer()
                    Text(boxVisible ? "Visible" : "Hidden")
                }
                .padding()

                HStack {
                    Text("Center:")
                    Spacer()
                    Text("\(box_center.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                }
                .padding()

                HStack {
                    Text("Rotation Angle:")
                    Spacer()
                    Text("\(rotate_angle, specifier: "%.2f") degrees")
                }
                .padding()

                HStack {
                    Text("Scale:")
                    Spacer()
                    Text("\(slider_xyz.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                }
                .padding()

            }.padding()
            .background(Color.gray.opacity(0.4)) // Light gray background with clear color
            .cornerRadius(10) // Rounded corners
    }
}

