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
            Spacer()
            // Steps
            VStack {
                Text("Steps:").bold().underline().font(.headline)
                    .padding(.bottom, -8)
                List(instructions, id: \.self) { instruction in
                    Text(instruction)
                }
                .listStyle(GroupedListStyle())
                        
            }
            
            // Best photogrammetry practices
            VStack {
                Spacer()
                Text("For Best Results:").bold().underline()
                List(bestPractices, id: \.self) { bestPractice in
                    Text(bestPractice)
                }
                .listStyle(GroupedListStyle())
//                Spacer()
            }
//            Spacer()
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Instructions")
        .navigationBarTitleDisplayMode(.inline)
        // --- Tool Bar ---
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Next", destination: BoundingBoxView(viewModel: viewModel)).environmentObject(dataModel)  // Link to Bounding Box View
                                .navigationViewStyle(.stack)
            }
        }
    }  // End of body
    
    let instructions = [
        "1) Place bounding box around the object.",
        "2) Take about 50-100 images of the object, covering all angles.",
        "3) Check image quality and delete any blurry images. Take more images if necessary.",
        "4) When you're happy with your images, send them to HMC Wayfair Clinic.",
    ]
    
    let bestPractices = [
        "1) Try to get uniform/consistent lighting (favor natural lighting).",
        "2) Capture the object from all angles (i.e. above, below, different side).",
        "3) For more detailed areas, you can get closer to take more photos."
    ]
}  // End of view
