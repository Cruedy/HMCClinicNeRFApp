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
    @State public var moveLeft: Bool = false
    @State public var moveRight: Bool = false
    @State public var rotate_angle: Float = 0
    
    @State public var slider_xyz: [Float] = [1,1,1]
//    @State public var arViewContainer: ARViewContainer

    @State public var mode =  0
    private let translateMode = 0
    private let rotateMode = 1
    private let scaleMode = 2

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight, rot: $rotate_angle, slider: $slider_xyz).edgesIgnoringSafeArea(.all)
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
                Spacer()
                // Offline Mode
                if case .Offline = viewModel.appState.appMode {
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
                        HStack{
                            // Button to create bounding box
                            VStack{
                                // manage the state specific buttons
                                if mode == translateMode{
                                    Button(action: {
                                        print("move left")
                                        moveLeft.toggle()
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                                            moveLeft = false
                                        }
                                    }) {
                                        Text("Left")
                                            .padding(.horizontal,20)
                                            .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    
                                    Button(action: {
                                        print("move right")
                                        moveRight.toggle()
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                                            moveRight = false
                                        }
                                    }) {
                                        Text("Right")
                                            .padding(.horizontal,20)
                                            .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                }
                                else if mode == rotateMode{
//                                    Button(action: {
//                                        print("rotate")
//                                        rotate_45.toggle()
//                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
//                                            rotate_45 = false
//                                        }
//                                    }) {
//                                        Text("Rotate 45")
//                                            .padding(.horizontal,20)
//                                            .padding(.vertical, 5)
//                                    }
//                                    .buttonStyle(.bordered)
//                                    .buttonBorderShape(.capsule)
                                    Slider(
                                        value: $rotate_angle,
                                        in: 0...359.5,
                                        step: 0.5
                                    )
                                    Text("\(rotate_angle, specifier: "angle (degrees): %.2f")")
                                }
                                else if mode == scaleMode{
                                    Slider(
                                        value: $slider_xyz[0],
                                        in: 0...5,
                                        step: 0.1
                                    )
                                    Text("\(slider_xyz[0], specifier: "X: %.2f")")
                                    
                                    Slider(
                                        value: $slider_xyz[1],
                                        in: 0...5,
                                        step: 0.1
                                    )
                                    Text("\(slider_xyz[1], specifier: "Y: %.2f")")
                                    
                                    Slider(
                                        value: $slider_xyz[2],
                                        in: 0...5,
                                        step: 0.1
                                    )
                                    Text("\(slider_xyz[2], specifier: "Z: %.2f")")
                                }
                            }
                            
                            VStack{
                                // manage state
                                Button(action: {
                                    print("Before: \(boxVisible)")
                                    boxVisible.toggle()
                                    print("After: \(boxVisible)")
                                }) {
                                    Text("Create Bounding Box")
                                        .padding(.horizontal,20)
                                        .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                
                                
                                Button(action: {
                                    print("enter translate mode")
                                    self.mode = translateMode
                                    
                                }) {
                                    Text("Move")
                                        .padding(.horizontal,20)
                                        .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                
                                Button(action: {
                                    print("enter rotate mode")
                                    self.mode = rotateMode
                                    
                                }) {
                                    Text("Rotate")
                                        .padding(.horizontal,20)
                                        .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                
                                Button(action: {
                                    print("enter scale mode")
                                    self.mode = scaleMode
                                    
                                }) {
                                    Text("Scale")
                                        .padding(.horizontal,20)
                                        .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)

                            }
                        }
                        
                        
                        
                        
                    }
                }
                
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
                NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel,  bv: $boxVisible, ml: $moveLeft, mr: $moveRight, rot: $rotate_angle, slider: $slider_xyz)).environmentObject(dataModel) // Link to Taking Images View
                                .navigationViewStyle(.stack)
            }
        }
        
    }  // End of body
}  // End of BoundingBoxVieew

#if DEBUG
struct BoundingBox_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
