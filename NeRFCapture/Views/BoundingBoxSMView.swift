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
    @StateObject private var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @Binding var path: NavigationPath // unused
    @Binding var currentView: NavigationDestination
    @State private var showSheet: Bool = false
    
    // controls the bounding box
    @State public var boxVisible: Bool = true
    @State public var box_center: [Float] = [0,0,0]
    @State public var rotate_angle: Float = 0.0
    @State public var slider_xyz: [Float] = [0.1,0.1,0.1]
    @State public var mode =  MovementModes.translate // start in the translate mode
    @State public var bbox_placement_states = BoundingBoxPlacementStates.IdentifyFloor
    
    // help button
    @State private var showingInstructions = false
    
    /**
        Initializes a new instance of the `BoundingBoxSMView` view.

        - Parameter viewModel: An instance of `ARViewModel` that will manage the augmented reality data and interactions.
        - Parameter path: A binding to a `NavigationPath` object which tracks the navigation state within the app. This parameter is currently unused in this view.
        - Parameter currentView: A binding to a `NavigationDestination` that tracks the current view in the navigation hierarchy.

        Note: The `path` parameter is marked as unused and might be reserved for future routing enhancements or navigation controls.
    */
    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>, currentView: Binding<NavigationDestination>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
        _currentView = currentView
    }

    @available(iOS 17.0, *)
    var body: some View {
        ZStack {
            // ARViewContainer with gesture recognizer
            ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    if let frame = viewModel.session?.currentFrame {
                        
                        // allows the user to tap to place box on the floor
                        if bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor{
                            viewModel.findFloorHeight(at: location, frame: frame)
                        }
                        
                        // used whenever the user can tap to reposition the box (including when placing on the floor)
                        if (bbox_placement_states == BoundingBoxPlacementStates.IdentifyFloor || bbox_placement_states == BoundingBoxPlacementStates.PlaceBox){
                            box_center = viewModel.raycast_bounding_box_center(at:location, frame: frame)
                        }
                    }
                }


            VStack {
                GeometryReader { geometry in
                    HStack {
                        // Place a Summary UI in the top left of the screen.
                        BoxSummaryView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz)
                            .frame(width: min(max(geometry.size.width * 0.3, 150), 300)) // 30% of screen width, min 150, max 300
                        Spacer()
                    }
                }
                Spacer()
                
                // This is the main content and takes up most of the screen
                self.content
                
                HelpButton {
                    showingInstructions = true
                }
                .sheet(isPresented: $showingInstructions) {
                    VStack {
                        InstructionsView()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Create Bounding Box")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown, use the currentView to change views programmatically.
    }
    
    
    // controls the content shown
    @available(iOS 17.0, *)
    private var content: some View {
        switch bbox_placement_states {
        
        // first, let the user the bounding box on the floor
        case .IdentifyFloor: return  AnyView(IdentifyFloorView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible,
                                                                 box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        
        // secondly, let the user input the dimension of the box
        case .InputDimensions: return AnyView(InputDimensionsView(vm: viewModel, states: $bbox_placement_states, place_box_mode: $mode, boxVisible: $boxVisible,
                                                                  box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz))
        
        // lastly, let the user fine tune the box to fit the object as best as they can
        case .PlaceBox: return AnyView(PlaceBoxView(vm: viewModel, states: $bbox_placement_states,
                                                    place_box_mode: $mode, boxVisible: $boxVisible, box_center: $box_center, rotate_angle: $rotate_angle, slider_xyz: $slider_xyz, currentView: $currentView))
        }
      }
}  // End of BoundingBoxView

// Enum used in switching between content
enum BoundingBoxPlacementStates {
    case IdentifyFloor
    case InputDimensions
    case PlaceBox
}

// unused
@available(iOS 17.0, *)
class BoundingBoxSMController<BoundingBoxSMView: View>: UIViewController {
    let boundingBoxSMView: BoundingBoxSMView
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
