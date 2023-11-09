//
//  IntroInstructionsView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI

struct IntroInstructionsView: View {
    @StateObject private var viewModel: ARViewModel
    @StateObject var dataModel = DataModel()
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack{
            Text("How to Use App")

        }
        .preferredColorScheme(.dark)
        .navigationBarTitle("Intro Instructions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: BoundingBoxView(viewModel: viewModel)).environmentObject(dataModel)
                                .navigationViewStyle(.stack)
            }
        }
    }
}
