//
//  BoundingBoxSM-InputDimensions.swift
//  NeRFCapture
//
//  Created by Clinic on 2/5/24.
//

import Foundation
import SwiftUI

@available(iOS 17.0, *)
struct InputDimensionsView : View {
    
    
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
    
        viewModel.display_box(boxVisible: boxVisible.wrappedValue)
        viewModel.set_center(new_center: box_center.wrappedValue)
        viewModel.set_angle(new_angle: rotate_angle.wrappedValue)
        viewModel.set_scale(new_scale: slider_xyz.wrappedValue)
//        ActionManager.shared.actionStream.send(.set_center(box_center.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_angle(rotate_angle.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_scale(slider_xyz.wrappedValue))
        }
    
    var body: some View{
        Spacer()
        Slider(
            value: $slider_xyz[0],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in
            slider_xyz = viewModel.set_scale(new_scale: new_scale)
        }
        Text("\(slider_xyz[0], specifier: "X: %.2f m")")
        
        Slider(
            value: $slider_xyz[1],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in
            slider_xyz = viewModel.set_scale(new_scale: new_scale)
        }
        Text("\(slider_xyz[1], specifier: "Y: %.2f m")")
        
        
        Slider(
            value: $slider_xyz[2],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in
            slider_xyz = viewModel.set_scale(new_scale: new_scale)
        }
        Text("\(slider_xyz[2], specifier: "Z: %.2f m")")
        
        HStack{
            Button(action: {
                bbox_placement_states = BoundingBoxPlacementStates.IdentifyFloor
            }) {
                Text("Back")
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            Button(action: {
                bbox_placement_states = BoundingBoxPlacementStates.PlaceBox
            }) {
                Text("Next")
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
    
    }

}


