//
//  IntroInstructionsView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI

struct HelpButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct InstructionsView: View {
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
    }
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
}

@available(iOS 17.0, *)
struct IntroInstructionsView: View {
    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @State var isAlertShown = false
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack{
            InstructionsView()
        }
        // --- Tool Bar ---
//        NavigationLink("next", destination: BoundingBoxSMView(viewModel: viewModel)).environmentObject(dataModel).navigationViewStyle(.stack)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                //might need to add this to the end of the navigation link
//            }
//        }
        Button("Start Project"){
            viewModel.datasetWriter.showAlert(
                viewModel: viewModel, 
                dataModel: dataModel,
                title: "Create Project Name",
                message: "Please provide a name for your project",
                hintText: "Enter Title",
                primaryTitle: "Submit",
                secondaryTitle: "Cancel",
                primaryAction: { text in
                    print(text)
                },
                secondaryAction: {
                    print("Cancelled")
                }
            )
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .environmentObject(dataModel)
    }  // End of body
}  // End of view

