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
    @State private var showSheet: Bool = false
    @State public var boxVisible: Bool = false
    @State public var moveLeft: Bool = false
    @State public var moveRight: Bool = false

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight).edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {
                            Spacer()
                            Picker("Mode", selection: $viewModel.appState.appMode) {
                                Text("Offline").tag(AppMode.Offline)
                            }
                            .navigationBarHidden(true) // prevents navigation bar from being shown in this view
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
                HStack(spacing: 20) {
                    Button("Left") {
                        
                        moveLeft = true
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                            moveLeft = false
                        }
                    }
                    Button("Right") {
                        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                        moveRight = true
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                            moveRight = false
                        }
                    }
                }
                if case .Offline = viewModel.appState.appMode {
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
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
                        
//                        Button(action: {
//                            print("reset cheat Before: \(boxVisible)")
//                            viewModel.resetWorldOrigin()
//                        }) {
//                            Text("Reset")
//                                .padding(.horizontal, 20)
//                                .padding(.vertical, 5)
//                        }
//                        .buttonStyle(.bordered)
//                        .buttonBorderShape(.capsule)
                        
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
                    }
                    NavigationLink("Next", destination: TakingImagesView(viewModel: viewModel))
//                    Button(action: {
//                        do {
//                            try viewModel.datasetWriter.initializeProject()
//                        }
//                        catch {
//                            print("\(error)")
//                        }
//                    }) {
//                        Text("Next")
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 5)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .buttonBorderShape(.capsule)
                }
                        
                if viewModel.appState.writerState == .SessionStarted {
                    Spacer()
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
    }
}

#if DEBUG
struct BoundingBox_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
