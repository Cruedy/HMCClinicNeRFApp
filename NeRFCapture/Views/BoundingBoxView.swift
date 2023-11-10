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

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight).edgesIgnoringSafeArea(.all)
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
                // Offline Mode
                if case .Offline = viewModel.appState.appMode {
                    if viewModel.appState.writerState == .SessionNotStarted {
                        Spacer()
                        // Button to create bounding box
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
}  // End of BoundingBoxVieew

#if DEBUG
struct BoundingBox_Previews : PreviewProvider {
    static var previews: some View {
        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
