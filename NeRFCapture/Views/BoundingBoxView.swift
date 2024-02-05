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
    
    // controls the bounding box
    @State public var boxVisible: Bool = false
    @State public var box_center: [Float] = [0,0,0]
    @State public var rotate_angle: Float = 0
    @State public var slider_xyz: [Float] = [0.1,0.1,0.1]
    @State public var mode =  MovementModes.translate // start in the translate mode
    
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
                            
                            // Pick bounding box mode
                            Picker("Translation Mode", selection: $mode) {
                                Text("Translate").tag(MovementModes.translate)
                                Text("Rotate").tag(MovementModes.rotate)
                                Text("Scale").tag(MovementModes.scale)
                                Text("Extend").tag(MovementModes.extend)
                                Text("Point Cloud").tag(MovementModes.pointCloud)
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
                            // TODO: Can probably move Create Bounding Box button out like the movement commands
                            Button(action: {
                                print("Before: \(boxVisible)")
                                boxVisible.toggle()
                                ActionManager.shared.actionStream.send(.display_box(boxVisible))
                                ActionManager.shared.actionStream.send(.set_center(box_center))
                                ActionManager.shared.actionStream.send(.set_angle(rotate_angle))
                                ActionManager.shared.actionStream.send(.set_scale(slider_xyz))
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
                                MovementControlsView(center: $box_center, vm: viewModel)
                            }
                            else if mode == MovementModes.rotate{
                                RotateControlsView(angle: $rotate_angle)
                            }
                            else if mode == MovementModes.scale{
                                ScaleControlsView(xyz: $slider_xyz)
                            }
                            else if mode == MovementModes.extend{
                                ExtendControlsView(vm: viewModel)
                            }
                            else if mode == MovementModes.pointCloud{
                                PointCloudControlsView(vm: viewModel)
                            }
                        }
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
        // --- Navigation Bar ---
        .navigationBarTitle("Create Bounding Box")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
        // --- Tool Bar ---
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
                    ActionManager.shared.actionStream.send(.set_center(box_center))

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
                        let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                        box_center = [box_center[0]-0.1*cos(-1*camera_angle!), box_center[1], box_center[2]-0.1*sin(-1*camera_angle!)]
                        ActionManager.shared.actionStream.send(.set_center(box_center))
                        
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
                        ActionManager.shared.actionStream.send(.set_center(box_center))

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
                    ActionManager.shared.actionStream.send(.set_center(box_center))

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
                    ActionManager.shared.actionStream.send(.set_center(box_center))

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
                    ActionManager.shared.actionStream.send(.set_center(box_center))

                }) {
                    Text("Down (-Y)")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                // end of up and down
            }
        }
    }

struct RotateControlsView : View {
    @Binding var rotate_angle: Float
    init(angle: Binding<Float>){
        _rotate_angle = angle
    }
    var body: some View {
        Slider(
            value: $rotate_angle,
            in: 0...359.5,
            step: 0.5

        ).onChange(of: rotate_angle) {new_angle in ActionManager.shared.actionStream.send(.set_angle(new_angle))}

        Text("\(rotate_angle, specifier: "angle (degrees): %.2f")")
    }
}

struct ScaleControlsView : View {
        @Binding var slider_xyz: [Float]
        init(xyz: Binding<[Float]>){
            _slider_xyz = xyz
        }
    
    var body: some View{
        Slider(
            value: $slider_xyz[0],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in ActionManager.shared.actionStream.send(.set_scale(new_scale))}
        Text("\(slider_xyz[0], specifier: "X: %.2f m")")
        
        Slider(
            value: $slider_xyz[1],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in ActionManager.shared.actionStream.send(.set_scale(new_scale))}
        Text("\(slider_xyz[1], specifier: "Y: %.2f m")")
        
        
        Slider(
            value: $slider_xyz[2],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in ActionManager.shared.actionStream.send(.set_scale(new_scale))}
        Text("\(slider_xyz[2], specifier: "Z: %.2f m")")
    }
}

//
//struct PressAndHoldButton: View {
//    @State private var timer: Timer?
//    @State var isLongPressing = false
//    // function action
//    
//    // init(action: a function){
//    // action = action
//    //}
//    var body: some View {
//        VStack {
//            
//            Button(action: {
//                print("tap")
//                if(self.isLongPressing){
//                    //this tap was caused by the end of a longpress gesture, so stop our fastforwarding
//                    self.isLongPressing.toggle()
//                    self.timer?.invalidate()
//                    
//                } else {
//                    //just a regular tap
//                    print("just Once")
//                    //do action
//                    
//                }
//            }, label: {
//                Image(systemName: self.isLongPressing ? "chevron.right.2": "chevron.right")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 30, height: 30)
//                
//            })
//            .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
//                print("long press")
//                self.isLongPressing = true
//                //or fastforward has started to start the timer
//                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
//                    print("your holding")
//                    // do action
//                })
//            })
//        }
//    }
//}

struct PressAndHoldButton: View {
    @State private var timer: Timer?
    @State var isLongPressing = false
    var action: (() -> Void) // Function to perform when button is held
    var title: String
    init(action: @escaping () -> Void, title: String) {
        self.action = action
        self.title = title
    }
    
    var body: some View {
        VStack {
            Button(action: {
                if self.isLongPressing {
                    // This tap was caused by the end of a long press gesture, so stop our fast forwarding
                    self.isLongPressing.toggle()
                    self.timer?.invalidate()
                } else {
                    // Perform the action once
                    self.action()
                }
            }) {
                Text(self.title)
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                self.isLongPressing = true
                // To start the timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                    // Perform the action continuously
                    self.action()
                })
            })
        }
    }
}

struct ExtendControlsView : View {
    @ObservedObject var viewModel: ARViewModel
    init(vm: ARViewModel){
        viewModel = vm
    }
    var body: some View {
        HStack{
            VStack{
                Spacer()
                Text("Extend Side")
                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.extend_sides([0,0,-0.1]))}, title:"front")
                HStack{
                    PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.extend_sides([-0.1,0,0]))}, title:"left")
                    PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.extend_sides([0.1,0,0]))}, title:"right")
                }
                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.extend_sides([0,0,0.1]))}, title:"back")
            }
            Spacer()
            VStack{
                Spacer()
                Text("Shrink Side")
                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.shrink_sides([0,0,0.1]))}, title:"front")
                HStack{
                    PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.shrink_sides([-0.1,0,0]))}, title:"right")
                    PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.shrink_sides([0.1,0,0]))}, title:"left")
                }
                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.shrink_sides([0,0,-0.1]))}, title:"back")
            }
        }
    }
}

struct PointCloudControlsView: View {
    @ObservedObject var viewModel: ARViewModel
    init(vm: ARViewModel){
        viewModel = vm
    }
    var body: some View {
        VStack{
            Spacer()
            
            if let frame = viewModel.session?.currentFrame {
                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.fit_point_cloud(frame))}, title:"Use PCL")
            }
            
//            Button(action: {
//                print("fitting around point cloud")
////                box_center = [box_center[0], box_center[1]+0.1, box_center[2]]
////                ActionManager.shared.actionStream.send(.set_center(box_center))
//                if let frame = viewModel.session?.currentFrame {
//                    print("I have a valid frame")
//                    ActionManager.shared.actionStream.send(.fit_point_cloud(frame))
//                }
//
//            }) {
//                Text("Use PCL")
//                    .padding(.horizontal,20)
//                    .padding(.vertical, 5)
//            }
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)
        }
    }
}
enum MovementModes {
    case translate
    case rotate
    case scale
    case extend
    case pointCloud
}

#if DEBUG
struct BoundingBox_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
