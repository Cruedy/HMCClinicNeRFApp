//
//  BoundingBoxSM-PlaceBox.swift
//  NeRFCapture
//
//  Created by Clinic on 2/5/24.
//

import Foundation


//
//  BoundingBoxSM-InputDimensions.swift
//  NeRFCapture
//
//  Created by Clinic on 2/5/24.
//

import Foundation
import SwiftUI

@available(iOS 17.0, *)
struct PlaceBoxView : View {
    @Binding var bbox_placement_states: BoundingBoxPlacementStates
    @Binding var place_box_mode: MovementModes
    @ObservedObject var viewModel: ARViewModel
    @Binding var currentView: NavigationDestination

    // controls the bounding box
    @Binding public var boxVisible: Bool
    @Binding public var box_center: [Float]
    @Binding public var rotate_angle: Float
    @Binding public var slider_xyz: [Float]

    /**
     Initializes a new instance of the `BoundingBoxSMView-PlaceBox` view. It is a helper for `BoundingBoxSMView`. This view allows the user to finetune the position, rotation, and scale of the box.

     - Parameter vm: An instance of `ARViewModel` that will manage the augmented reality data and interactions.
     - Parameter states: A binding to `BoundingBoxPlacementStates` used to change to change the content in BoundingBoxSMView.
     - Parameter place_box_mode: A binding to a `MovementModes` enum.
     - Parameter boxVisible: A binding to track the visibility of the box throughout Boundingbox interactions
     - Parameter box_center: A binding to track the center coordinate of the box (x,y,z) throughout
     - Parameter rotate_angle: A binding to track the angle of the box (degrees) throughout
     - Parameter slider_xyz: A binding to track the dimension of the box (along x,y,z axis) throughout
    */
    init( vm: ARViewModel, states: Binding<BoundingBoxPlacementStates>, place_box_mode: Binding<MovementModes>,
          boxVisible: Binding<Bool>, box_center: Binding<[Float]>, rotate_angle: Binding<Float>, slider_xyz: Binding<[Float]>, currentView: Binding<NavigationDestination>){
            viewModel = vm
            _bbox_placement_states = states
            _place_box_mode = place_box_mode
            _boxVisible = boxVisible
            _box_center = box_center
            _rotate_angle = rotate_angle
            _slider_xyz = slider_xyz
            _currentView = currentView
        
        // updates the bounding box location upon creating this view.
        viewModel.display_box(boxVisible: boxVisible.wrappedValue)
        viewModel.set_center(new_center: box_center.wrappedValue)
        viewModel.set_angle(new_angle: rotate_angle.wrappedValue)
        viewModel.set_scale(new_scale: slider_xyz.wrappedValue)
        }
    
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                VStack() {
                    ZStack() {
                        HStack() {  // HStack because originally showed Offline/Online mode
                            Spacer()
                            // Pick bounding box controls mode
                            Picker("Translation Mode", selection: $place_box_mode) {
                                Text("Translate").tag(MovementModes.translate)
                                Text("Rotate").tag(MovementModes.rotate)
                                Text("Scale").tag(MovementModes.scale)
                                Text("Extend").tag(MovementModes.extend)
                            }
                            .frame(maxWidth: 200)
                            .padding(0)
                            .pickerStyle(.segmented)

                            Spacer()
                        }
                    }.padding(8)
                }
            }
            
            VStack {
                    VStack{
                        Spacer()
                        GeometryReader { geometry in
                            Text("Tap on the screen to reposition the box. Use the buttons to translate, rotate, and expand/shrink the box.")
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
                        
                        // Updates the controls between translating the box, rotating the box, and scaling and extending the box
                        HStack{
                            if place_box_mode == MovementModes.translate{
                                MovementControlsView(center: $box_center, vm: viewModel)
                            }
                            else if place_box_mode == MovementModes.rotate{
                                RotateControlsView(angle: $rotate_angle, vm: viewModel)
                            }
                            else if place_box_mode == MovementModes.scale{
                                ScaleControlsView(xyz: $slider_xyz, vm: viewModel)
                            }
                            
                            else if place_box_mode == MovementModes.extend{
                                ExtendControlsView(center: $box_center, xyz: $slider_xyz, vm: viewModel)
                            }
                        }
                        
                        // Moves to the user to a totally new view. `takingImagesView` allows users to collect image data with guidance.
                        Button("Complete Bounding Box") {
                            currentView = .takingImagesView
                        }
                            .padding(.horizontal,20)
                            .padding(.vertical, 5)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                    }
            }
        }
    }


}

