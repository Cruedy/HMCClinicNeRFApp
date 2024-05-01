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
    @Binding var path: NavigationPath // Unused
    @Binding var currentView: NavigationDestination
    @State private var showAlert = false

    /**
        Initializes a new instance of the `VideoView` view.

        - Parameter viewModel: An instance of `ARViewModel` that will manage the augmented reality data and interactions.
        - Parameter path: A binding to a `NavigationPath` object which tracks the navigation state within the app. This parameter is currently unused in this view.
        - Parameter currentView: A binding to a `NavigationDestination` that tracks the current view in the navigation hierarchy.

        Note: The `path` parameter is marked as unused and might be reserved for future routing enhancements or navigation controls.
    */
    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>, currentView: Binding<NavigationDestination>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
        _currentView = currentView
    }

    var body: some View {
        let splatName = viewModel.datasetWriter.projName
        Text(splatName) // title
        let defaultURL = URL(string: "http://osiris.cs.hmc.edu:15002/webviewer/")!
                
        Link("Open Web Viewer", destination: URL(string: viewModel.datasetWriter.webViewerUrl) ?? defaultURL)
                    .padding()
                    .foregroundColor(.blue)
        let videoURL = viewModel.datasetWriter.projectDir.appendingPathComponent("\(splatName).mp4")
        VideoPlayer(player: AVPlayer(url: videoURL))
        
        HStack {
            Button("Back") {
                currentView = .sendImagesToServerView // change the View by setting currentView to the previous View.
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
                                appDelegate.resetApplication() // Resets the application; is bugged correctly.
                            }
                        } message: {
                            Text("If you return to start, you will not be able to return to this view. Your splat will still be online at \(viewModel.datasetWriter.webViewerUrl)")
                        }
        }

    }
}
