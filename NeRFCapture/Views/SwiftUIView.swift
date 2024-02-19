//
//  SwiftUIView.swift
//  NeRFCapture
//
//  Created by Clinic on 1/22/24.
//

//import SwiftUI
//
//struct SwiftUIView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//#Preview {
//    SwiftUIView()
//}


import SwiftUI
import RealityKit
import ARKit

struct PointCloudBoundingBoxView: View {
    @State private var isScanning = false
    @State private var boundingBoxCenter: SIMD3<Float>?
    @State private var boundingBoxExtent: SIMD3<Float>?
    
    let arSession: ARSession // Inject ARSession
    
    init(arSession: ARSession) {
        self.arSession = arSession
    }

    var body: some View {
        VStack {
            // Start Scanning Button
            Button(action: {
                // Start scanning action
                startScanning()
            }) {
                Text("Start Scanning")
                    .font(.title)
                    .padding()
            }

            // End Scanning Button
            Button(action: {
                // End scanning action
                endScanning()
            }) {
                Text("End Scanning")
                    .font(.title)
                    .padding()
            }

            // Display Bounding Box Center and Extent
            if let center = boundingBoxCenter, let extent = boundingBoxExtent {
                Text("Bounding Box Center: \(formatSIMD3(center))")
                Text("Bounding Box Extent: \(formatSIMD3(extent))")
            }
        }
    }

    private func startScanning() {
        print("started scanning")
        // Trigger your bounding box generation function here.
        // Assuming you have a valid ARSession and ARFrame:
        if let frame = arSession.currentFrame {
            print("i have a valid frame")
            if let boundingBoxData = createBoundingBoxForPointCloud(frame: frame) {
                boundingBoxCenter = boundingBoxData.center
                boundingBoxExtent = boundingBoxData.size
                print("should be printing if we have any data")
                print("Bounding box center \(boundingBoxCenter) and Bounding box extent \(boundingBoxExtent)")
            }
        }
    }

    private func endScanning() {
        // Freeze the bounding box center and extent.
        // You can add your logic here to stop updating the bounding box.
    }
    
    // Helper function to format SIMD3<Float> as a string
    private func formatSIMD3(_ vector: SIMD3<Float>) -> String {
        return String(format: "(%.2f, %.2f, %.2f)", vector.x, vector.y, vector.z)
    }
}


struct BoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        let arSession = ARSession() // Create or obtain your ARSession instance here
        let pointCloudBoundingBoxView = PointCloudBoundingBoxView(arSession: arSession)
    }
}
