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
    @EnvironmentObject var dataModel: DataModel
    
    @State private var showSheet: Bool = false
    
    // controls the bounding box
    @State public var boxVisible: Bool = true
    @State public var box_center: [Float] = [0,0,0]
    @State public var rotate_angle: Float = 90.0
    @State public var slider_xyz: [Float] = [0.1,0.1,0.1]
    @State public var mode =  MovementModes.translate // start in the translate mode
    @State public var bbox_placement_states = BoundingBoxPlacementStates.IdentifyFloor
    
    // help button
    @State private var showingInstructions = false
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }

    @available(iOS 17.0, *)
    var body: some View {
        ZStack {
            // ARViewContainer with gesture recognizer
            ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    if let frame = viewModel.session?.currentFrame {
                        if bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor{
                            viewModel.findFloorHeight(at: location, frame: frame)
                        }
                        if (bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor || bbox_placement_states == BoundingBoxPlacementStates.PlaceBox){
                            box_center = viewModel.raycast_bounding_box_center(at:location, frame: frame)
                        }
                    }
                }

//            VStack {
//                HStack{
//                    BoxSummaryView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz)
//                    Spacer()
//                }
//                Spacer()
//                self.content
//            }
            VStack {
                GeometryReader { geometry in
                    HStack {
                        BoxSummaryView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz)
                            .frame(width: min(max(geometry.size.width * 0.3, 150), 300)) // 30% of screen width, min 150, max 300
                        Spacer()
                    }
                }
                Spacer()
                self.content
                NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel).environmentObject(dataModel)).navigationViewStyle(.stack)
            }
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Create Bounding Box")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
        // --- Tool Bar ---
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//
//            }
//        }
    }
    
    
    @available(iOS 17.0, *)
    private var content: some View {
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


@available(iOS 17.0, *)
class BoundingBoxSMController<BoundingBoxSMView: View>: UIViewController {
    let boundingBoxSMView: BoundingBoxSMView
//    let environmentObject: EnvironmentObject<DataModel>
    let dataModel: DataModel
    
    init(boundingBoxSMView: BoundingBoxSMView, dataModel: DataModel) {
        self.boundingBoxSMView = boundingBoxSMView
        self.dataModel = dataModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Embed the SwiftUI view within a UIHostingController
//        let hostingController = UIHostingController(rootView: boundingBoxSMView.environmentObject(dataModel))
        let hostingController = UIHostingController(rootView: boundingBoxSMView)
        
        // Add the hosting controller as a child of this view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Adjust the frame of the hosting controller's view
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Finish adding the hosting controller
        hostingController.didMove(toParent: self)
    }
}


enum BoundingBoxPlacementStates {
    case IdentifyFloor
    case InputDimensions
    case PlaceBox
}

@available(iOS 17.0, *)
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
