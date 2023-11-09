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
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            IntroInstructionsView(viewModel: viewModel)
        }
        .environmentObject(dataModel)
        .navigationViewStyle(.stack)
    }
}
