//
//  BoundingBoxSMView.swift
//  NeRFCapture
//
//  Created by Eric Chen on 2/6/24.
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 17.0, *)
struct BoundingBoxSMView: View {
//    @ObservedObject var viewModel: ContentViewModel
    @StateObject private var viewModel: ARViewModel
    @StateObject var dataModel = DataModel()
    @State private var showSheet: Bool = false
    
    // controls the bounding box
    @State public var boxVisible: Bool = true
    @State public var box_center: [Float] = [0,0,0]
    @State public var rotate_angle: Float = 0
    @State public var slider_xyz: [Float] = [0.1,0.1,0.1]
    @State public var mode =  MovementModes.translate // start in the translate mode
    @State public var bbox_placement_states = BoundingBoxPlacementStates.IdentifyFloor
    
    // help butto
    @State private var showingInstructions = false
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
//    @available(iOS 17.0, *)
//    var body: some View {
//        ZStack{
//            
//            ZStack{
//                ZStack(alignment: .topTrailing) {
//                    ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz).edgesIgnoringSafeArea(.all)
//                        .onTapGesture(coordinateSpace: .global) { location in
//                            if let frame = viewModel.session?.currentFrame {
//                                if bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor{
//                                    IdentifyFloorView.raycast_bounding_box(at: location, frame: frame)
//                                }
//                            }
//                        }
//                    VStack() {
//                        ZStack() {
//                            HStack() {  // HStack because originally showed Offline/Online mode
//                                Spacer()
//                                
//                                // Shows mode is Offline
//                                Picker("Mode", selection: $viewModel.appState.appMode) {
//                                    Text("Offline").tag(AppMode.Offline)
//                                }
//                                
//                                Spacer()
//                            }
//                        }.padding(8)
//                    }
//                }   // End of inner ZStack
//                
//                VStack {
//                    // Offline Mode
//                    if case .Offline = viewModel.appState.appMode {
//                        VStack{
//                            Spacer()
//                            self.content
//                        }
//                    }
//                    HelpButton {
//                        showingInstructions = true
//                    }
//                    .sheet(isPresented: $showingInstructions) {
//                        VStack {
//                            InstructionsView()
//                        }
//                    }
//                }  // End of inner VStack
//                .padding()
//                
//            } // End of main ZStack
//            .preferredColorScheme(.dark)
//            .navigationBarTitle("Create Bounding Box")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
//            // --- Tool Bar ---
//            .toolbar {
//                if bbox_placement_states == BoundingBoxPlacementStates.PlaceBox {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel))
//                            .environmentObject(dataModel) // Link to Taking Images View
//                            .navigationViewStyle(.stack)
//                    }
//                }
//            }
//            .border(.green, width: 5)
//            
//
//            Button(action: {
//                switch bbox_placement_states {
//                case .IdentifyFloor:  bbox_placement_states = BoundingBoxPlacementStates.InputDimensions
//                case .InputDimensions:  bbox_placement_states = BoundingBoxPlacementStates.PlaceBox
//                case .PlaceBox:  bbox_placement_states = BoundingBoxPlacementStates.PlaceBox
//                }
//            }) {
//                Text("Done")
//                    .padding(.horizontal,20)
//                    .padding(.vertical, 5)
//            }
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)
//        
//        .contentShape(Rectangle())
//        }
//    }  // End of body
    
    
    @available(iOS 17.0, *)
    var body: some View {
        ZStack {
            // ARViewContainer with gesture recognizer
            ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    if let frame = viewModel.session?.currentFrame {
                        if bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor{
                            ActionManager.shared.actionStream.send(.set_floor(location, frame))
                        }
                        if (bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor || bbox_placement_states == BoundingBoxPlacementStates.PlaceBox){
                            ActionManager.shared.actionStream.send(.raycast_center(location, frame))
                            slider_xyz = viewModel.get_box_scale()
                            box_center = viewModel.get_box_center()
                            rotate_angle = viewModel.get_box_rotation()
                        }
                    }
                }

            VStack {
                // Place buttons or other controls here
                Spacer()
                self.content
            }
        }
    }
    
    @available(iOS 17.0, *)
    private var content: some View {
//        slider_xyz = viewModel.get_box_scale()
//        box_center = viewModel.get_box_center()
//        rotate_angle = viewModel.get_box_rotation()
        
//        print(slider_xyz)
        switch bbox_placement_states {
        case .IdentifyFloor: return  AnyView(IdentifyFloorView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible,
                                                                 box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        case .InputDimensions: return AnyView(InputDimensionsView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible,
                                                                  box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        case .PlaceBox: return AnyView(PlaceBoxView(vm: viewModel, states: $bbox_placement_states,
                                                    place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        }
      }
}  // End of BoundingBoxView


enum BoundingBoxPlacementStates {
    case IdentifyFloor
    case InputDimensions
    case PlaceBox
}


struct TestView: View {
    @ObservedObject var viewModel: ARViewModel
    init(vm: ARViewModel){
        viewModel = vm
    }
    var body: some View {
        VStack{
            Spacer()
            Text("hello")
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
struct BoundingBoxSM_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxSMView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
