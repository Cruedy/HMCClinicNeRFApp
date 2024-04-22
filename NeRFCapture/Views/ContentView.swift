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
    @State private var path = NavigationPath()
    @State private var currentView: NavigationDestination = .introInstructionsView

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            switch currentView {
            case .introInstructionsView:
                IntroInstructionsView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)
            case .boundingBoxSMView:
                BoundingBoxSMView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)
            case .takingImagesView:
                TakingImagesView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)
            case .gridView:
                GridView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)
            case .sendImagesToServerView:
                SendImagesToServerView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)
            case .videoView:
                VideoView(viewModel: viewModel, path: $path, currentView: $currentView).environmentObject(dataModel)

            }
        }
        
//        NavigationStack(path: $path) {
//            IntroInstructionsView(viewModel: viewModel, path: $path)  // Start on IntroInstructions view
//                .environmentObject(dataModel)
//        }
    }
}

// Assuming you have an enum for navigation states:
enum NavigationDestination: Hashable {
    case introInstructionsView
    case boundingBoxSMView
    case takingImagesView
    case gridView
    case sendImagesToServerView
    case videoView
}
