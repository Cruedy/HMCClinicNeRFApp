//
//  BoundingBoxSMView.swift
//  NeRFCapture
//
//  Created by Eric Chen on 2/6/24.
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 16.0, *)
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
    @State public var bbox_placement_states = BoundingBoxPlacementStates.InputDimensions
    
    // help button
    @State private var showingInstructions = false
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz).edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {  // HStack because originally showed Offline/Online mode
                            Spacer()
                            
                            // Shows mode is Offline
                            Picker("Mode", selection: $viewModel.appState.appMode) {
                                Text("Offline").tag(AppMode.Offline)
                            }
                            
                            Spacer()
                        }
                    }.padding(8)
                }
            }   // End of inner ZStack
            
            VStack {
                // Offline Mode
                if case .Offline = viewModel.appState.appMode {
                    VStack{
                        Spacer()
                        self.content
                        
                    }
                }
                HelpButton {
                    showingInstructions = true
                }
                .sheet(isPresented: $showingInstructions) {
                    VStack {
                        InstructionsView()
                    }
                }
            }  // End of inner VStack
            .padding()
            
        } // End of main ZStack
        .preferredColorScheme(.dark)
        .navigationBarTitle("Create Bounding Box")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
        // --- Tool Bar ---
        .toolbar {
            if bbox_placement_states == BoundingBoxPlacementStates.PlaceBox {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel))
                        .environmentObject(dataModel) // Link to Taking Images View
                        .navigationViewStyle(.stack)
                }
            }
        }
        
        
    }  // End of body
    
    
    private var content: some View {
//        switch mode {
//
//        case .translate: return AnyView(MovementControlsView(center: $box_center, vm: viewModel))
//        case .rotate: return AnyView(TestView(vm: viewModel))
//        case .scale: return AnyView(TestView(vm: viewModel))
//        case .pointCloud: return AnyView(PointCloudControlsView(vm: viewModel))
//        case .extend: return AnyView(TestView(vm: viewModel))
//        }
        switch bbox_placement_states {
        case .InputDimensions: return AnyView(InputDimensionsView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible,
                                                                  box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        case .PlaceBox: return AnyView(PlaceBoxView(vm: viewModel, states: $bbox_placement_states,
                                                    place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
//        case .BoxPlaced: return AnyView(PlaceBoxView(vm: viewModel, states: $bbox_placement_states,
//                                                 place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        }
      }
}  // End of BoundingBoxView


enum BoundingBoxPlacementStates {
    case InputDimensions
    case PlaceBox
//    case BoxPlaced
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
@available(iOS 16.0, *)
struct BoundingBoxSM_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxSMView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
