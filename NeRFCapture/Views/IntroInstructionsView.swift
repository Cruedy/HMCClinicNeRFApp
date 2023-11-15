//
//  IntroInstructionsView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI

struct IntroInstructionsView: View {
    @StateObject var viewModel: ARViewModel
    @StateObject var dataModel = DataModel()
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack {  // Main UI portion
            // TODO: Fill with instructions for using the app
            Text("How to Use App")
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Intro Instructions")
        .navigationBarTitleDisplayMode(.inline)
        // --- Tool Bar ---
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: BoundingBoxView(viewModel: viewModel)).environmentObject(dataModel)  // Link to Bounding Box View
                                .navigationViewStyle(.stack)
            }
        }
    }  // End of body
}  // End of view
