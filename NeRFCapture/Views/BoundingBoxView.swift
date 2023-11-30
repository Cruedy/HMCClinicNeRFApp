//
//  BoundingBoxView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import ARKit
import RealityKit

struct BoundingBoxView: View {
    @StateObject private var viewModel: ARViewModel
    @StateObject var dataModel = DataModel()
    @State private var showSheet: Bool = false
    @State public var boxVisible: Bool = false
//    @State public var moveLeft: Bool = false
//    @State public var moveRight: Bool = false
    @State public var box_center: [Float] = [0,0,0]
    @State public var rotate_angle: Float = 0
    @State public var slider_xyz: [Float] = [0.1,0.1,0.1]
//    @State public var arViewContainer: ARViewContainer

    @State public var mode =  MovementModes.translate
//    private let translateMode = 0
//    private let rotateMode = 1
//    private let scaleMode = 2

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, cet: $box_center, rot: $rotate_angle, slider: $slider_xyz).edgesIgnoringSafeArea(.all)
//                _arViewContainer.edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {  // HStack because originally showed Offline/Online mode
                            // TODO: Make this show different views for translating/rotating/resizing bounding box
                            Spacer()
                            
                            // Shows mode is Offline
                            Picker("Mode", selection: $viewModel.appState.appMode) {
                                Text("Offline").tag(AppMode.Offline)
                            }
                            
                            Picker("Translation Mode", selection: $mode) {
                                Text("Translate").tag(MovementModes.translate)
                                Text("Rotate").tag(MovementModes.rotate)
                                Text("Scale").tag(MovementModes.scale)
                                Text("Extend").tag(MovementModes.extend)

                            }
                            .frame(maxWidth: 200)
                            .padding(0)
                            .pickerStyle(.segmented)
                            .disabled(viewModel.appState.writerState
                                      != .SessionNotStarted)
    
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

                        HStack{
                            Spacer()
                            Button(action: {
                                print("Before: \(boxVisible)")
                                boxVisible.toggle()
                                ActionManager.shared.actionStream.send(.display_box(boxVisible))
                                ActionManager.shared.actionStream.send(.update_center(box_center))
                                ActionManager.shared.actionStream.send(.update_rotate(rotate_angle))
                                ActionManager.shared.actionStream.send(.update_scale(slider_xyz))

                                print("After: \(boxVisible)")
                            }) {
                                Text("Create Bounding Box")
                                    .padding(.horizontal,20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                        
                            HStack{
                                if mode == MovementModes.translate{
                                    // start of move state
                                    MovementControlsView(center: $box_center, vm: viewModel)
                                }
                                else if mode == MovementModes.rotate{
                                    RotateControlsView(angle: $rotate_angle)
                                }
                                else if mode == MovementModes.scale{
                                    ScaleControlsView(xyz: $slider_xyz)
                                }
                            }
                        }
                    }
//                }
                
            }  // End of inner VStack
            .padding()
            
        } // End of main ZStack
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Create Bounding Box")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown        // --- Tool Bar ---
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel)).environmentObject(dataModel) // Link to Taking Images View
                                .navigationViewStyle(.stack)
            }
        }
        
    }  // End of body
}  // End of BoundingBoxView


struct MovementControlsView : View
    {
        @ObservedObject var viewModel: ARViewModel
        @Binding var box_center: [Float]
        init(center: Binding<[Float]>, vm: ARViewModel){
            _box_center = center
            viewModel = vm
        }
        var body: some View {
            VStack{
                Spacer()
                // Start of left right forward back
                Button(action: {
                    print("move forward")
                    let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                    box_center = [box_center[0]+0.1*sin(-1*camera_angle!), box_center[1], box_center[2]-0.1*cos(-1*camera_angle!)]
                    ActionManager.shared.actionStream.send(.update_center(box_center))

                }) {
                    Text("Forward (-Z)")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                HStack{
                    Button(action: {
                        print("move left")
                        ActionManager.shared.actionStream.send(.heartbeat("HELLO WORLD"))
                        
                        let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                        box_center = [box_center[0]-0.1*cos(-1*camera_angle!), box_center[1], box_center[2]-0.1*sin(-1*camera_angle!)]
                        ActionManager.shared.actionStream.send(.update_center(box_center))
                        
                    }) {
                        Text("Left (-X)")
                            .padding(.horizontal,20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button(action: {
                        print("move right")
                        let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                        box_center = [box_center[0]+0.1*cos(-1*camera_angle!), box_center[1], box_center[2]+0.1*sin(-1*camera_angle!)]
                        ActionManager.shared.actionStream.send(.update_center(box_center))

                    }) {
                        Text("Right (+X)")
                            .padding(.horizontal,20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                
                Button(action: {
                    print("move Back")
                    let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                    box_center = [box_center[0]-0.1*sin(-1*camera_angle!), box_center[1], box_center[2]+0.1*cos(-1*camera_angle!)]
                    ActionManager.shared.actionStream.send(.update_center(box_center))

                }) {
                    Text("Back (+Z)")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                // End of left right forward back
            }
            Spacer()
            VStack{
                Spacer()
                // up and down
                Button(action: {
                    print("move up")
                    box_center = [box_center[0], box_center[1]+0.1, box_center[2]]
                    ActionManager.shared.actionStream.send(.update_center(box_center))

                }) {
                    Text("Up (+Y)")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                Button(action: {
                    print("move down")
                    box_center = [box_center[0], box_center[1]-0.1, box_center[2]]
                    ActionManager.shared.actionStream.send(.update_center(box_center))

                }) {
                    Text("Down (-Y)")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                // end of up and down
            }
            
            // end of move state
        }
        
    }

struct RotateControlsView : View {
//    @ObservedObject var viewModel: ARViewModel
    @Binding var rotate_angle: Float
    init(angle: Binding<Float>){
        _rotate_angle = angle
//        viewModel = vm
    }
    var body: some View {
        Slider(
            value: $rotate_angle,
            in: 0...359.5,
            step: 0.5,
            onEditingChanged: { editing in
                if !editing {
                    ActionManager.shared.actionStream.send(.update_rotate(rotate_angle))
                }
            }

        )
        Text("\(rotate_angle, specifier: "angle (degrees): %.2f")")
    }
}

struct ScaleControlsView : View {
    //    @ObservedObject var viewModel: ARViewModel
        @Binding var slider_xyz: [Float]
        init(xyz: Binding<[Float]>){
            _slider_xyz = xyz
    //        viewModel = vm
        }
    
    var body: some View{
        Slider(
            value: $slider_xyz[0],
            in: 0...5,
            step: 0.1,
            onEditingChanged: { editing in
                if !editing {
                    ActionManager.shared.actionStream.send(.update_scale(slider_xyz))
                }
            }
        )
        Text("\(slider_xyz[0], specifier: "X: %.2f m")")
        
        Slider(
            value: $slider_xyz[1],
            in: 0...5,
            step: 0.1,
//                                        onEditingChanged: { editing in
//                                            if !editing {
//                                                ActionManager.shared.actionStream.send(.update_scale(slider_xyz))
//                                            }
//                                        }
            onEditingChanged: { _ in
                ActionManager.shared.actionStream.send(.update_scale(slider_xyz))
            }
        )
        Text("\(slider_xyz[1], specifier: "Y: %.2f m")")
        
        
        Slider(
            value: $slider_xyz[2],
            in: 0...5,
            step: 0.1,
            onEditingChanged: { editing in
                if !editing {
                    ActionManager.shared.actionStream.send(.update_scale(slider_xyz))
                }
            }
        )
        Text("\(slider_xyz[2], specifier: "Z: %.2f m")")
    }
}
    
enum MovementModes {
    case translate
    case rotate
    case scale
    case extend
}

#if DEBUG
struct BoundingBox_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
