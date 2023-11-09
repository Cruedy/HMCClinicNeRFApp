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
    @StateObject var dataModel = DataModel()
    @State private var showSheet: Bool = false
    @State private var isLinkActive = false
    @State private var showNavigationLink = false // Set this variable to control visibility

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
//                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight).edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {
                            Spacer()
                            Picker("Mode", selection: $viewModel.appState.appMode) {
                                Text("Offline").tag(AppMode.Offline)
                            }
                            .navigationBarBackButtonHidden(true) // prevents navigation bar from being shown in this view
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
            }
            VStack {
                Spacer()
//                HStack(spacing: 20) {
//                    Button("Left") {
//
//                        moveLeft = true
//                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
//                            moveLeft = false
//                        }
//                    }
//                    Button("Right") {
//                        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
//                        moveRight = true
//                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
//                            moveRight = false
//                        }
//                    }
//                }
                if case .Offline = viewModel.appState.appMode {
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
                        
                        Button(action: {
                            viewModel.resetWorldOrigin()
                        }) {
                            Text("Reset")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
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
                        
//                        Button(action: {
//                                if let frame = viewModel.session?.currentFrame {
//                                    viewModel.ddsWriter.writeFrameToTopic(frame: frame)
//                                }
//                            }) {
//                                Text("Send")
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 5)
//                            }
//                            .buttonStyle(.borderedProminent)
//                            .buttonBorderShape(.capsule)
                        
//                        NavigationLink("Next", destination: GridView()).environmentObject(dataModel)
//                                        .navigationViewStyle(.stack)
                    }
                }
                        
                if viewModel.appState.writerState == .SessionStarted {
                    Spacer()
                    Button(action: {
                        viewModel.datasetWriter.finalizeProject()
                    }) {
                        Text("End")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
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
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .navigationBarTitle("Take Images")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: GridView()).environmentObject(dataModel)
                                .navigationViewStyle(.stack)
            }
        }
    }
}
