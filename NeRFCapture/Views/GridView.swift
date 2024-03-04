//
//  GridView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/5/23.
//

import SwiftUI

@available(iOS 17.0, *)
struct GridView : View {
    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel

    private static let initialColumns = 3
    @State private var isAddingPhoto = false // This is where user retakes the photo
    @State private var isEditing = false // This is where the user removes photos

    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var numColumns = initialColumns
    
    @State private var showingInstructions = false
    
    private var columnsTitle: String {
        gridColumns.count > 1 ? "\(gridColumns.count) Columns" : "1 Column"
    }
    
    var body: some View {
        VStack {
            if isEditing {
                ColumnStepper(title: columnsTitle, range: 1...8, columns: $gridColumns)
                .padding()
            }
            // View that shows all the images
            ScrollView {
                LazyVGrid(columns: gridColumns) {
                    ForEach(dataModel.items) { item in
                        GeometryReader { geo in
                            NavigationLink(destination: DetailView(item: item)) {
                                GridItemView(size: geo.size.width, item: item)
                            }
                        }
                        .cornerRadius(8.0)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(alignment: .topTrailing) {
                            if isEditing {
                                Button {
                                    withAnimation {
                                        dataModel.removeItem(item)
                                    }
                                } label: {
                                    Image(systemName: "xmark.square.fill")
                                                .font(Font.title)
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .red)
                                }
                                .offset(x: 7, y: -7)
                            }
                        }
                    }
                }
                .padding()
            }
            Button(action: {
                viewModel.datasetWriter.finalizeProject()
            }){
                Text("Prepare Files")
            }
            NavigationLink("Next", destination: SendImagesToServerView())
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
            
            HelpButton {
                showingInstructions = true
            }
            .sheet(isPresented: $showingInstructions) {
                VStack {
                    InstructionsView()
                }
            }
        }  // End of main VStack
        // --- Navigation Bar ---
        .navigationBarTitle("Image Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingPhoto) {
            PhotoPicker()
        }
        // Removed from toolbar because toolbars dont show up
        Button(isEditing ? "Done" : "Edit") {
            withAnimation { isEditing.toggle() }
        }
        // --- Tool Bar ---
//        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                
//            }
//        }
        
    }
}

//struct GridView_Previews: PreviewProvider {
//    static var previews: some View {
//        GridView().environmentObject(DataModel())
//            .previewDevice("iPad (8th generation)")
//    }
//}
