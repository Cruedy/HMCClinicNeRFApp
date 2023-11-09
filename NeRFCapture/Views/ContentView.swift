//
//  ContentView.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 16.0, *)

struct ContentView : View {
    @StateObject private var viewModel: ARViewModel
    @StateObject var dataModel = DataModel()
    @State private var curView = 0  // 0 = intro, 1 = bounding box, 2 = take image, 3 = edit images, 4 = send to server
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        IntroInstructionsView(viewModel: viewModel)
//        switch curView {
//        case 0:
//            IntroInstructionsView(viewModel: viewModel)
//        case 1:
//            BoundingBoxView(viewModel: viewModel)
//        case 2:
//            TakingImagesView(viewModel: viewModel)
//        case 3:
//            GridView()
//                .environmentObject(dataModel)
//                .navigationViewStyle(.stack)
//        case 4:
//            SendImagesToServerView()
//        default:
//            IntroInstructionsView(viewModel: viewModel)
//        }
        
    }
    
    //        NavigationStack {
    //            IntroInstructionsView(viewModel: viewModel)
    //            BoundingBoxView(viewModel: viewModel)
    //            TakingImagesView(viewModel: viewModel)
    //            GridView()
    //                .environmentObject(dataModel)
    //                .navigationViewStyle(.stack)
    //            SendImagesToServerView()
    //        }
    
//    @StateObject private var viewModel: ARViewModel
//    @State private var showContentView1 = true
//    @StateObject var dataModel = DataModel()
//
//    init(viewModel vm: ARViewModel) {
//        _viewModel = StateObject(wrappedValue: vm)
//    }
//
//    var body: some View {
//        VStack {
//            if showContentView1 {
//                ContentView(viewModel: viewModel)
//                Spacer()
//                Button(action: {
//                    viewModel.datasetWriter.finalizeProject()
//                    showContentView1.toggle()
//                }) {
//                    Text("End")
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 5)
//                }
//                .buttonStyle(.bordered)
//                .buttonBorderShape(.capsule)
//            } else {
//                NavigationStack {
//                    GridView()
//                }
//                .environmentObject(dataModel)
//                .navigationViewStyle(.stack)
//                Button("Retake") {
//                    showContentView1.toggle()
//                }
//            }
//
//            Button("Switch View") {
//                showContentView1.toggle()
//            }
//        }
//    }
}
