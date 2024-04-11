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
    @Binding var path: NavigationPath
    @State private var projectName: String = ""
    @State private var isAlertShown = false
    @State private var shouldNavigate = false

    var body: some View {
        VStack {
            InstructionsView()

            Button("Start Project") {
                isAlertShown = true
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            // Programmatically activated NavigationLink
            NavigationLink("", destination: BoundingBoxSMView(viewModel: viewModel, path: $path).environmentObject(dataModel), isActive: $shouldNavigate)
        }
        .alert("Create Project Name", isPresented: $isAlertShown) {
            TextField("Enter Title", text: $projectName).foregroundColor(.green)
            Button("Cancel", role: .cancel) { }
            Button("Submit") {
                viewModel.datasetWriter.projName = projectName
                print(viewModel.datasetWriter.projName)
                shouldNavigate = true // Triggers navigation
            }
        } message: {
            Text("Please provide a name for your project")
        }
        .environmentObject(dataModel)
    }
}
//struct IntroInstructionsView: View {
//    @StateObject var viewModel: ARViewModel
//    @EnvironmentObject var dataModel: DataModel
//    @Binding var path: NavigationPath // Add this line
//    @State private var projectName: String = "" // Use this for conditional navigation
//    @State var isAlertShown = false
//    
//    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>) {
//        _viewModel = StateObject(wrappedValue: vm)
//        _path = path // Bind the path
//
//    }
//    
//    
//    
//    var body: some View {
//        VStack{
//            InstructionsView()
////        }
//        
////        var body: some View {
////            VStack {
////                InstructionsView()
//                // Hidden NavigationLink that triggers navigation when projectName has a value
////            NavigationLink("Complete Bounding Box", destination: TakingImagesView(viewModel: viewModel, path: $path).environmentObject(dataModel)).navigationViewStyle(.stack)
////                .padding(.horizontal,20)
////                .padding(.vertical, 5)
////                .buttonStyle(.bordered)
////                .buttonBorderShape(.capsule)
//            
//            
//            NavigationLink("Proceed to Bounding Box Creation", destination: BoundingBoxSMView(viewModel: viewModel, path: $path).environmentObject(dataModel)).navigationViewStyle(.stack)
//                .padding(.horizontal,20)
//                .padding(.vertical, 5)
//                .buttonStyle(.bordered)
//                .buttonBorderShape(.capsule)
//            
//                Button("Start Project") {
//                    isAlertShown = true
//                }
//                .buttonStyle(.bordered)
//                .buttonBorderShape(.capsule)
//            }
//            .alert("Create Project Name", isPresented: $isAlertShown, actions: {
//                TextField("Enter Title", text: $projectName)
//                Button("Cancel", role: .cancel) { }
//                Button("Submit") {
//                    // Perform the navigation by setting projectName which changes selection binding of NavigationLink
//                    // Optional: Perform any actions needed with projectName before navigating
//                }
//            }, message: {
//                Text("Please provide a name for your project")
//            })
//            .environmentObject(dataModel)
//        }
//    }
//        
//        
//
////        Button("Start Project"){
////            viewModel.datasetWriter.showAlert(
////                viewModel: viewModel, 
////                dataModel: dataModel,
////                path: $path,
////                title: "Create Project Name",
////                message: "Please provide a name for your project",
////                hintText: "Enter Title",
////                primaryTitle: "Submit",
////                secondaryTitle: "Cancel",
////                primaryAction: { text in
////                    print(text)
////                },
////                secondaryAction: {
////                    print("Cancelled")
////                }
////            )
////        }
////        .buttonStyle(.bordered)
////        .buttonBorderShape(.capsule)
////        .environmentObject(dataModel)
////    }  // End of body
////}  // End of view
//
