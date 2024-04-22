//
//  VideoView.swift
//  NeRFCapture
//
//  Created by Clinic on 3/31/24.
//

import AVKit
import SwiftUI
import Foundation


@available(iOS 17.0, *)
struct VideoView: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @Binding var path: NavigationPath // Add this line
    @Binding var currentView: NavigationDestination
    @State private var showAlert = false // State variable to toggle alert visibility




    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>, currentView: Binding<NavigationDestination>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
        _currentView = currentView
    }

    var body: some View {
        let splatName = viewModel.datasetWriter.projName
        Text(splatName)
        let defaultURL = URL(string: "http://osiris.cs.hmc.edu:15002/webviewer/")!
                
        Link("Open Web Viewer", destination: URL(string: viewModel.datasetWriter.webViewerUrl) ?? defaultURL)
                    .padding()
                    .foregroundColor(.blue)
        let videoURL = viewModel.datasetWriter.projectDir.appendingPathComponent("\(splatName).mp4")
        VideoPlayer(player: AVPlayer(url: videoURL))
        
        HStack {
            Button("Back") {
                currentView = .sendImagesToServerView
            }
            .padding(.horizontal,20)
            .padding(.vertical, 5)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            Button("Return to Start") {
                showAlert = true // Show the alert when button is tapped

            }
                .padding(.horizontal,20)
                .padding(.vertical, 5)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .alert("Confirm Return", isPresented: $showAlert) {
                            Button("Cancel", role: .cancel) {} // No action needed for cancel, just closes the alert
                            Button("Confirm", role: .destructive) {
                                appDelegate.resetApplication() // Resets the application
                            }
                        } message: {
                            Text("If you return to start, you will not be able to return to this view. Your splat may be stilled online at \(viewModel.datasetWriter.webViewerUrl)")
                        }
        }
        
        
//
//        Button("Return to Start") {
////            path.removeAll()
////            path.wrappedValue.removeAll()
//            print(path.count)
//        }
//        .padding()
//        .buttonStyle(.bordered)
        
//        let newViewModel = ARViewModel(datasetWriter: datasetWriter, ddsWriter: ddsWriter)
//        // let contentView = ContentView(viewModel: viewModel)
//        let contentView = ContentView(viewModel: viewModel)
        
//        NavigationStack {
//            IntroInstructionsView(viewModel: viewModel)  // Start on IntroInstructions view
//        }
//        .environmentObject(dataModel)
//        .navigationViewStyle(.stack)
//        NavigationLink("Create a New Splatt", destination: IntroInstructionsView(viewModel: viewModel).environmentObject(dataModel)
//).navigationViewStyle(.stack)
//            .padding(.horizontal, 20)
//            .padding(.vertical, 5)
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)

    }
}
