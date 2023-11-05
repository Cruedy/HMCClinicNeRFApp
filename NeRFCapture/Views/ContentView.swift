//
//  ContentView.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import SwiftUI
import ARKit
import RealityKit

struct ContentView : View {
    @StateObject private var viewModel: ARViewModel
    @State private var showSheet: Bool = false
    @State public var boxVisible: Bool = false
    @State public var moveLeft: Bool = false
    @State public var moveRight: Bool = false

    
    init(viewModel vm: ARViewModel) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        ZStack{
            ZStack(alignment: .topTrailing) {
                ARViewContainer(vm: viewModel, bv: $boxVisible, ml: $moveLeft, mr: $moveRight).edgesIgnoringSafeArea(.all)
                VStack() {
                    ZStack() {
                        HStack() {
//                            Button() {
//                                showSheet.toggle()
//                            } label: {
//                                Image(systemName: "gearshape.fill")
//                                    .imageScale(.large)
//                            }
//                            .padding(.leading, 16)
//                            .buttonStyle(.borderless)
//                            .sheet(isPresented: $showSheet) {
//                                VStack() {
//                                    Text("Settings")
//                                    Spacer()
//                                }
//                                .presentationDetents([.medium])
//                            }
//                            Spacer()
                        }
                        HStack() {
                            Spacer()
                            Picker("Mode", selection: $viewModel.appState.appMode) {
                                // Text("Online").tag(AppMode.Online)
                                Text("Offline").tag(AppMode.Offline)
                            }
                            .frame(maxWidth: 200)
                            .padding(0)
                            .pickerStyle(.segmented)
                            .disabled(viewModel.appState.writerState
                                      != .SessionNotStarted)
                            
                            Spacer()
                        }
                    }.padding(8)
                    HStack() {
                        Spacer()
                        
                        VStack(alignment:.leading) {
                            Text("\(viewModel.appState.trackingState)")
//                            if case .Online = viewModel.appState.appMode {
//                                Text("\(viewModel.appState.ddsPeers) Connection(s)")
//                            }
                            if case .Offline = viewModel.appState.appMode {
                                if case .SessionStarted = viewModel.appState.writerState {
                                    Text("\(viewModel.datasetWriter.currentFrameCounter) Frames")
                                }
                            }
                            
                            if viewModel.appState.supportsDepth {
                                Text("Depth Supported")
                            }
                        }.padding()
                    }
                }
            }
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button("Left") {
                        
                        moveLeft = true
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                            moveLeft = false
                        }
                    }
                    Button("Right") {
                        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
                        moveRight = true
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.01){
                            moveRight = false
                        }
                    }
                }
                HStack(spacing: 20) {
//                    if case .Online = viewModel.appState.appMode {
//                        Spacer()
//                        Button(action: {
//                            print("Before: \(boxVisible)")
//                            boxVisible.toggle()
//                            print("After: \(boxVisible)")
//                        }) {
//                            Text("Trigger Update 2")
//                                .padding(.horizontal,20)
//                                .padding(.vertical, 5)
//                        }
//                        .buttonStyle(.bordered)
//                        .buttonBorderShape(.capsule)
////                        .onChange(of: triggerUpdate) { triggerUpdate in
////                            $viewModel.triggerUpdate = triggerUpdate
////                             }
//                        
//                        Button(action: {
//                            print("reset cheat Before: \(boxVisible)")
//                            viewModel.resetWorldOrigin()
//                        }) {
//                            Text("Reset")
//                                .padding(.horizontal, 20)
//                                .padding(.vertical, 5)
//                        }
//                        .buttonStyle(.bordered)
//                        .buttonBorderShape(.capsule)
//                        Button(action: {
//                            if let frame = viewModel.session?.currentFrame {
//                                viewModel.ddsWriter.writeFrameToTopic(frame: frame)
//                            }
//                        }) {
//                            Text("Send")
//                                .padding(.horizontal, 20)
//                                .padding(.vertical, 5)
//                        }
//                        .buttonStyle(.borderedProminent)
//                        .buttonBorderShape(.capsule)
//                    }
                    if case .Offline = viewModel.appState.appMode {
                        if viewModel.appState.writerState == .SessionNotStarted {
                            Spacer()
                            Button(action: {
                                print("Before: \(boxVisible)")
                                boxVisible.toggle()
                                print("After: \(boxVisible)")
                            }) {
                                Text("Trigger Update 2")
                                    .padding(.horizontal,20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            
                            Button(action: {
                                print("reset cheat Before: \(boxVisible)")
                                viewModel.resetWorldOrigin()
                            }) {
                                Text("Reset")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            
                            Button(action: {
                                    if let frame = viewModel.session?.currentFrame {
                                        viewModel.ddsWriter.writeFrameToTopic(frame: frame)
                                    }
                                }) {
                                    Text("Send")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 5)
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.capsule)
                            }
                            
//                            Button(action: {
//                                viewModel.resetWorldOrigin()
//                            }) {
//                                Text("Reset")
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 5)
//                            }
//                            .buttonStyle(.bordered)
//                            .buttonBorderShape(.capsule)
                            
                            Button(action: {
                                do {
                                    try viewModel.datasetWriter.initializeProject()
                                }
                                catch {
                                    print("\(error)")
                                }
                            }) {
                                Text("Start")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                        
                        if viewModel.appState.writerState == .SessionStarted {
                            Spacer()
                            Button(action: {
                                viewModel.datasetWriter.finalizeProject()
                            }) {
                                Text("End")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            Button(action: {
                                if let frame = viewModel.session?.currentFrame {
                                    viewModel.datasetWriter.writeFrameToDisk(frame: frame)
                                }
                            }) {
                                Text("Save Frame")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                    }
                }
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }


struct ContentView2 : View {
    @EnvironmentObject var dataModel: DataModel

    private static let initialColumns = 3
    @State private var isAddingPhoto = false // This is where user retakes the photo
    @State private var isEditing = false // This is where the user removes photos

    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var numColumns = initialColumns
    
    private var columnsTitle: String {
        gridColumns.count > 1 ? "\(gridColumns.count) Columns" : "1 Column"
    }
    
    var body: some View {
        VStack {
            if isEditing {
                ColumnStepper(title: columnsTitle, range: 1...8, columns: $gridColumns)
                .padding()
            }
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
        }
        .navigationBarTitle("Image Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingPhoto) {
            PhotoPicker()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation { isEditing.toggle() }
                }
            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(isEditing ? "" : "Retake"){
//                    isAddingPhoto = true
//                }
//                // .disabled(isEditing)
//            }
        }
    }
}

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
                Button("Swatch") {
                    showContentView1.toggle()
                }
            } else {
                NavigationStack {
                    ContentView2()
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

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
            .previewInterfaceOrientation(.portrait)
    }
}
#endif
