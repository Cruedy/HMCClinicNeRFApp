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
        viewModel.display_box(boxVisible: boxVisible.wrappedValue)
        viewModel.set_center(new_center: box_center.wrappedValue)
        viewModel.set_angle(new_angle: rotate_angle.wrappedValue)
        viewModel.set_scale(new_scale: slider_xyz.wrappedValue)
//        ActionManager.shared.actionStream.send(.display_box(boxVisible.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_center(box_center.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_angle(rotate_angle.wrappedValue))
//        ActionManager.shared.actionStream.send(.set_scale(slider_xyz.wrappedValue))
        }
    
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                VStack() {
                    ZStack() {
                        HStack() {  // HStack because originally showed Offline/Online mode
                            Spacer()
                            // Pick bounding box mode
                            Picker("Translation Mode", selection: $place_box_mode) {
                                Text("Translate").tag(MovementModes.translate)
                                Text("Rotate").tag(MovementModes.rotate)
                                Text("Scale").tag(MovementModes.scale)
                                Text("Extend").tag(MovementModes.extend)
//                                Text("Point Cloud").tag(MovementModes.pointCloud)
                            }
                            .frame(maxWidth: 200)
                            .padding(0)
                            .pickerStyle(.segmented)

                            Spacer()
                        }
                    }.padding(8)
                }
            }   // End of inner ZStack
            
            VStack {
                // Offline Mode
                    VStack{
                        Spacer()
                        
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
//                            else if place_box_mode == MovementModes.pointCloud{
//                                PointCloudControlsView(vm: viewModel)
//                            }
                        }
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

