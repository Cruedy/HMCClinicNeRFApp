//
//  IntroInstructionsView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI

struct IntroInstructionsView: View {
    @StateObject private var viewModel: ARViewModel
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Intro Instructions")
                NavigationLink("Go to Make Bounding Box", destination: BoundingBoxView(viewModel: viewModel))
            }
        }
    }
}
