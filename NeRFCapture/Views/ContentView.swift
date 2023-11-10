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
