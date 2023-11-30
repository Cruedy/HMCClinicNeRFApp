//
//  SendImagesToServerView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import Zip


struct SendImagesToServerView: View {
    @State private var showingInstructions = false
    
    var body: some View {
        VStack{  // Main UI portion
            // TODO: Fill with instructions for sending images to the server
            Text("Send images to server")
            Spacer()
            HelpButton {
                showingInstructions = true
            }
            .sheet(isPresented: $showingInstructions) {
                VStack {
                    InstructionsView()
                }
            }
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Send to Server")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
    }
}
