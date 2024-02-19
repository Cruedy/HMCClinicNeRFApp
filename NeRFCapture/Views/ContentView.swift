////
////  ContentView.swift
////  NeRFCapture
////
////  Created by Jad Abou-Chakra on 13/7/2022.
////
//
//import SwiftUI
//import ARKit
//import RealityKit
//
//@available(iOS 16.0, *)
//
//struct ContentView : View {
//    @StateObject private var viewModel: ARViewModel  // For bounding box
//    @StateObject var dataModel = DataModel()  // For image gallery
//    private var arSession = ARSession()
//
//    
//    init(viewModel vm: ARViewModel) {
//        _viewModel = StateObject(wrappedValue: vm)
//        // Configure the ARSession
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.planeDetection = .horizontal // You can customize the configuration
//
//        // Run the ARSession
//        arSession.run(configuration)
//    }
//    
////    struct ContentView : View {
////        @StateObject private var viewModel: ARViewModel  // For bounding box
////        @StateObject var dataModel = DataModel()  // For image gallery
////
////        // Create a new ARSession instance
////        private var arSession = ARSession()
////
////        init(viewModel vm: ARViewModel) {
////            _viewModel = StateObject(wrappedValue: vm)
////
////            // Configure the ARSession
////            let configuration = ARWorldTrackingConfiguration()
////            configuration.planeDetection = .horizontal // You can customize the configuration
////
////            // Run the ARSession
////            arSession.run(configuration)
////        }
////
////        var body: some View {
////            PointCloudBoundingBoxView(arSession: arSession)
////        }
////    }
//
//    
//    var body: some View {
////        let arSession = ARSession() // Create or obtain your ARSession instance here
////        let configuration = ARWorldTrackingConfiguration() // Configure your ARSession
////        arSession.run(configuration)
////        let pointCloudBoundingBoxView = PointCloudBoundingBoxView(arSession: arSession)
//        PointCloudBoundingBoxView(arSession: arSession)
//       //        NavigationStack {
////            IntroInstructionsView(viewModel: viewModel)  // Start on IntroInstructions view
////        }
////        .environmentObject(dataModel)
////        .navigationViewStyle(.stack)
//    }
//}


//import SwiftUI
//import ARKit
//import RealityKit
//
//@available(iOS 16.0, *)
//
//struct ContentView : View {
//    @StateObject private var viewModel: ARViewModel  // For bounding box
//    @StateObject var dataModel = DataModel()  // For image gallery
//    
//    @State private var isBoundingBoxVisible = false  // To control the visibility of the bounding box view
//    
//    init(viewModel vm: ARViewModel) {
//        _viewModel = StateObject(wrappedValue: vm)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            IntroInstructionsView(viewModel: viewModel)  // Start on IntroInstructions view
//        }
//        .environmentObject(dataModel)
//        .navigationViewStyle(.stack)
//        
//        // BoundingBoxView (visible when isBoundingBoxVisible is true)
//        if isBoundingBoxVisible {
//            BoundingBoxView(arSession: viewModel.arSession)
//                .transition(.opacity)
//                .animation(.easeInOut)
//        }
//        
//        // Button to toggle visibility of the BoundingBoxView
//        Button(action: {
//            isBoundingBoxVisible.toggle()
//        }) {
//            Text("Toggle Bounding Box")
//                .font(.title)
//                .padding()
//        }
//    }
//}
//

//
//  ContentView.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 17.0, *)

struct ContentView : View {
    @StateObject private var viewModel: ARViewModel  // For bounding box
    @StateObject var dataModel = DataModel()  // For image gallery
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            IntroInstructionsView(viewModel: viewModel)  // Start on IntroInstructions view
        }
        .environmentObject(dataModel)
        .navigationViewStyle(.stack)
    }
}
