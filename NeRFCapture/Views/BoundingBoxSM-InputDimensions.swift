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
    
    /**
     Initializes a new instance of the `BoundingBoxSMView-InputDimensions` view. It is a helper for `BoundingBoxSMView`

     - Parameter vm: An instance of `ARViewModel` that will manage the augmented reality data and interactions.
     - Parameter states: A binding to `BoundingBoxPlacementStates` used to change to change the content in BoundingBoxSMView.
     - Parameter place_box_mode: A binding to a `MovementModes` enum. (unused)
     - Parameter boxVisible: A binding to track the visibility of the box throughout Boundingbox interactions
     - Parameter box_center: A binding to track the center coordinate of the box (x,y,z) throughout
     - Parameter rotate_angle: A binding to track the angle of the box (degrees) throughout
     - Parameter slider_xyz: A binding to track the dimension of the box (along x,y,z axis) throughout

     Note: The `place_box_mode` parameter is unused, but added to keep constructors between the different helper views consistent. It is a stylistic choice, but you may safely remove it.
    */
    init( vm: ARViewModel, states: Binding<BoundingBoxPlacementStates>, place_box_mode: Binding<MovementModes>,
          boxVisible: Binding<Bool>, box_center: Binding<[Float]>, rotate_angle: Binding<Float>, slider_xyz: Binding<[Float]>){
        viewModel = vm
        _bbox_placement_states = states
        _place_box_mode = place_box_mode
        _boxVisible = boxVisible
        _box_center = box_center
        _rotate_angle = rotate_angle
        _slider_xyz = slider_xyz
    
        // sets all properties of the box, visibility, center, angle, and scale/dimension
        viewModel.display_box(boxVisible: boxVisible.wrappedValue)
        viewModel.set_center(new_center: box_center.wrappedValue)
        viewModel.set_angle(new_angle: rotate_angle.wrappedValue)
        viewModel.set_scale(new_scale: slider_xyz.wrappedValue)
        }
    
    var body: some View{
        Spacer()
        
        // three sliders to change the three dimensions of the box
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
        
        
        // Go to another step/state
        HStack{
            // Back to placing the box on the floor
            Button(action: {
                bbox_placement_states = BoundingBoxPlacementStates.IdentifyFloor
            }) {
                Text("Back")
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            // Next to finetune the box
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


