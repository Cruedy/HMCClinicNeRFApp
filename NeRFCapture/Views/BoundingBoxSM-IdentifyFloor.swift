//
//  BoundingBoxSM-InputDimensions.swift
//  NeRFCapture
//
//  Created by Clinic on 2/5/24.
//

import Foundation
import SwiftUI
import ARKit

@available(iOS 17.0, *)
struct IdentifyFloorView : View {
    @Binding var bbox_placement_states: BoundingBoxPlacementStates
    @Binding var place_box_mode: MovementModes
    @ObservedObject var viewModel: ARViewModel
    
    // controls the bounding box
    @Binding public var boxVisible: Bool
    @Binding public var box_center: [Float]
    @Binding public var rotate_angle: Float
    @Binding public var slider_xyz: [Float]
    
    /**
     Initializes a new instance of the `BoundingBoxSMView-IndentifyFloor` view. It is a helper for `BoundingBoxSMView`

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
        VStack{
            
            Spacer()
            
            // Helpful instructions to user
            GeometryReader { geometry in
                Text("Tap on the screen to place the BoundingBox on a surface.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.20) // Sets the height to 20% of the screen.
                    .background(Color.blue.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.5) // Allows the font size to scale down if the text exceeds the frame bounds.
            }
            .edgesIgnoringSafeArea(.all) // Ensures the view extends to the edges of the display.
            
            // Moves the user to the next step in bounding box creation
            Button(action: {
                bbox_placement_states = BoundingBoxPlacementStates.InputDimensions
            }) {
                Text("Enter Dimensions")
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
    }
}
