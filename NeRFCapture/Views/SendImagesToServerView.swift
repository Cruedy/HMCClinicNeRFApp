//
//  SendImagesToServerView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI



struct SendImagesToServerView: View {
    
    var body: some View {
        VStack{  // Main UI portion
            // TODO: Fill with instructions for sending images to the server
            Text("Give images to Josh+Rohan")
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Send to Server")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
    }
}
