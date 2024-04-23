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
//        ActionManager.shared.actionStream.send(.display_box(boxVisible.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_center(box_center.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_angle(rotate_angle.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_scale(slider_xyz.wrappedValue))
    }
    
    var body: some View{
        VStack{
            
            Spacer()
            GeometryReader { geometry in
                Text("Tap on the screen to place the BoundingBox on a surface.")
                    .font(.title) // Sets the font type to title style.
                    .fontWeight(.bold) // Makes the font bold.
                    .foregroundColor(.white) // Sets the text color to white.
                    .padding() // Adds padding around the text.
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.20) // Sets the height to 20% of the screen.
                    .background(Color.blue.opacity(0.5)) // Sets the background color to blue with 50% transparency.
                    .multilineTextAlignment(.center) // Aligns text to the center of its container.
                    .lineLimit(nil) // Allows the text to wrap to multiple lines if needed.
                    .minimumScaleFactor(0.5) // Allows the font size to scale down if the text exceeds the frame bounds.
            }
            .edgesIgnoringSafeArea(.all) // Ensures the view extends to the edges of the display.
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
    
//    public static func raycast_bounding_box(at tap: CGPoint, frame: ARFrame) {
//        print(tap)
//        // Use the tap point to perform raycasting and place the bounding box
//        ActionManager.shared.actionStream.send(.set_floor(tap, frame))
//        ActionManager.shared.actionStream.send(.raycast_center(tap, frame))
//    }
}
