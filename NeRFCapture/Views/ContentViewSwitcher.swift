//
//  ContentViewSwitcher.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/5/23.
//

import SwiftUI

@available(iOS 16.0, *)
struct ContentViewSwitcher: View {
    @StateObject private var viewModel: ARViewModel
    @State private var showContentView1 = true
    @StateObject var dataModel = DataModel()
    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        VStack {
            if showContentView1 {
                ContentView(viewModel: viewModel)
                Spacer()
                Button(action: {
                    viewModel.datasetWriter.finalizeProject()
                    showContentView1.toggle()
                }) {
                    Text("End")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            } else {
                NavigationStack {
                    GridView()
                }
                .environmentObject(dataModel)
                .navigationViewStyle(.stack)
                Button("Retake") {
                    showContentView1.toggle()
                }
            }
            
//            Button("Switch View") {
//                showContentView1.toggle()
//            }
        }
    }
}
