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

    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @Binding var path: NavigationPath // Add this line
//    @Binding private var webViewerUrl: String
    @Binding var currentView: NavigationDestination


    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>, currentView: Binding<NavigationDestination>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
//        _webViewerUrl = ""
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
        
        Button("Back to intro") {
            currentView = .introInstructionsView
        }
            .padding(.horizontal,20)
            .padding(.vertical, 5)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        
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
