//
//  TakingImagesView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import ARKit
import RealityKit

struct TakingImagesView: View {
    @StateObject private var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
//    @StateObject var dataModel = DataModel()
    @State private var showSheet: Bool = false
//    @State public var boxVisible: Bool = false
//    @State public var moveLeft: Bool = false
//    @State public var moveRight: Bool = false
//    @State public var rotate_angle: Float = 0.0
//    @State public var slider: [Float] = [1,1,1]
    
    @Binding var boxVisible: Bool
    @Binding var moveLeft: Bool
    @Binding var moveRight: Bool
    @Binding var rotate_angle: Float
    @Binding var slider: [Float]

    // TODO: Only make navigation link active after image collection session is complete
    @State private var isLinkActive = false
    @State private var showNavigationLink = false // Set this variable to control visibility

    
    init(viewModel vm: ARViewModel, bv: Binding<Bool>, ml: Binding<Bool>, mr: Binding<Bool>, rot: Binding<Float>, slider: Binding<[Float]>) {
        _viewModel = StateObject(wrappedValue: vm)
        _boxVisible = bv
        _moveLeft = ml
        _moveRight = mr
        _rotate_angle = rot
        _slider = slider
        
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight, rot: $rotate_angle, slider: $slider).edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {  // HStack because originally showed Offline/Online mode
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
                    HStack() {
                        Spacer()
                        
                        // Relevant information about image collection session
                        VStack(alignment:.leading) {
                            Text("\(viewModel.appState.trackingState)")

                            if case .Offline = viewModel.appState.appMode {
                                if case .SessionStarted = viewModel.appState.writerState {
                                    Text("\(viewModel.datasetWriter.currentFrameCounter) Frames")
                                }
                            }
                            
                            if viewModel.appState.supportsDepth {
                                Text("Depth Supported")
                            }
                        }.padding()
                    }
                }
            }  // End of inner ZStack
            
            VStack {
                Spacer()

                if case .Offline = viewModel.appState.appMode {
                    
                    // View when not taking images
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
                        
                        // Button to reset world origin
                        Button(action: {
                            viewModel.resetWorldOrigin()
                        }) {
                            Text("Reset")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        // Button to start image collection session
                        Button(action: {
                            do {
                                try viewModel.datasetWriter.initializeProject()
                            }
                            catch {
                                print("\(error)")
                            }
                        }) {
                            Text("Start")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        
                        // Button to send the data
                        Button(action: {
                                if let frame = viewModel.session?.currentFrame {
                                    viewModel.ddsWriter.writeFrameToTopic(frame: frame)
                                }
                            }) {
                                Text("Send")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        
                    }   // End of case SessionNotStarted
                }
                
                // View when taking images
                if viewModel.appState.writerState == .SessionStarted {
                    Spacer()
                    // Button to end the image collection session
                    Button(action: {
                        viewModel.datasetWriter.finalizeSession()
                        dataModel.initializeGallery()
                    }) {
                        Text("End")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    // Button to save the current frame
                    Button(action: {
                        if let frame = viewModel.session?.currentFrame {
                            viewModel.datasetWriter.writeFrameToDisk(frame: frame)
                        }
                    }) {
                        Text("Save Frame")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }  // End of case SessionStarted
            }
            .padding()
            
        }  // End of main ZStack
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Take Images")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
        // --- Tool Bar ---
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: GridView(viewModel: viewModel)).environmentObject(dataModel)
                                .navigationViewStyle(.stack)
            }
        }
        
    }  // End of body
}   // End of TakingImagesView
