//
//  SendImagesToServerView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI



struct SendImagesToServerView: View {
    
    var body: some View {
        VStack{
            Text("Give images to Josh+Rohan")
                .navigationBarBackButtonHidden(true) // prevents navigation bar from being shown in this view
        }
        .preferredColorScheme(.dark)
        .navigationBarTitle("Send to Server")
        .navigationBarTitleDisplayMode(.inline)
    }
}
