//
//  BoundingBoxView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import ARKit
import RealityKit

enum MovementModes {
    case translate
    case rotate
    case scale
    case extend
    case pointCloud
}

@available(iOS 17.0, *)
struct MovementControlsView : View
    {
        @ObservedObject var viewModel: ARViewModel
        @Binding var box_center: [Float]
    
        /**
        A view for translating the bounding box.
         
        - Parameter center: A binding to an array of floats representing the x,y,z coordinates of the center of the box.
        - Parameter vm: The ARViewModel that holds the `BoundingBox` object and methods for updating it.
         */
        init(center: Binding<[Float]>, vm: ARViewModel){
            _box_center = center
            viewModel = vm
        }
    
        var body: some View {
            VStack{
                Spacer()
                
                // Each Button updates the bounding box in one direction, relative to the camera. There are 6 in total.
                
                // Start of left right forward back
                Button(action: {
                    print("move forward")
                    
                    // Notice here we make adjustments so that movements are not axis aligned to the world coordinates but the camera's local reference view.
                    let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                    box_center = [box_center[0]+0.1*sin(-1*camera_angle!), box_center[1], box_center[2]-0.1*cos(-1*camera_angle!)]
                    
                    // Calls a helper function in viewModel to update the box, and also updates the state with the return value.
                    box_center = viewModel.set_center(new_center: box_center)
                }) {
                    Text("Forward")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                HStack{
                    Button(action: {
                        print("move left")
                        let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                        box_center = [box_center[0]-0.1*cos(-1*camera_angle!), box_center[1], box_center[2]-0.1*sin(-1*camera_angle!)]
                        box_center = viewModel.set_center(new_center: box_center)
                    }) {
                        Text("Left")
                            .padding(.horizontal,20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button(action: {
                        print("move right")
                        let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                        box_center = [box_center[0]+0.1*cos(-1*camera_angle!), box_center[1], box_center[2]+0.1*sin(-1*camera_angle!)]
                        box_center = viewModel.set_center(new_center: box_center)
                    }) {
                        Text("Right")
                            .padding(.horizontal,20)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                
                Button(action: {
                    print("move Back")
                    let camera_angle = viewModel.arView?.session.currentFrame?.camera.eulerAngles.y
                    box_center = [box_center[0]-0.1*sin(-1*camera_angle!), box_center[1], box_center[2]+0.1*cos(-1*camera_angle!)]
                    box_center = viewModel.set_center(new_center: box_center)
                }) {
                    Text("Back")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                // End of left right forward back
            }
            Spacer()
            VStack{
                Spacer()
                // up and down
                Button(action: {
                    print("move up")
                    box_center = [box_center[0], box_center[1]+0.1, box_center[2]]
                    box_center = viewModel.set_center(new_center: box_center)
                }) {
                    Text("Up")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                
                Button(action: {
                    print("move down")
                    box_center = [box_center[0], box_center[1]-0.1, box_center[2]]
                    box_center = viewModel.set_center(new_center: box_center)
                }) {
                    Text("Down")
                        .padding(.horizontal,20)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                // end of up and down
            }
        }
    }

@available(iOS 17.0, *)
struct RotateControlsView : View {
    @ObservedObject var viewModel: ARViewModel
    @Binding var rotate_angle: Float
    
    /**
     A view for updating the angle of the bounding box, rotated about the y-axis (rotation parallel to the ground plane).
     
     - Parameter angle: a binding to a float representing the angle about the y-axis that is in radian
     - Parameter vm: The ARViewModel that holds the `BoundingBox` object and methods for updating it.
     */
    init(angle: Binding<Float>, vm: ARViewModel){
        _rotate_angle = angle
        viewModel = vm
    }
    var body: some View {
        Slider(
            value: $rotate_angle,
            in: 0...359.5,
            step: 0.5

        ).onChange(of: rotate_angle) {new_angle in
            print(new_angle)
            
            // updates the angle of the box using the viewModel and also update the value of rotate_angle
            rotate_angle = viewModel.set_angle(new_angle: new_angle)
        }.padding(15)
        Text("\(rotate_angle, specifier: "angle (degrees): %.2f")")
    }
}

@available(iOS 17.0, *)
struct ScaleControlsView : View {
    @ObservedObject var viewModel: ARViewModel
    @Binding var slider_xyz: [Float]
    
    /**
    A view for changing the dimension of each side of the bounding box.
     
    - Parameter center: A binding to an array of floats representing the x,y,z dimension of the box.
    - Parameter vm: The ARViewModel that holds the `BoundingBox` object and methods for updating it.
     */
    init(xyz: Binding<[Float]>, vm: ARViewModel){
        _slider_xyz = xyz
        viewModel = vm
    }
    
    var body: some View{
        Slider(
            value: $slider_xyz[0], // the 0th element is the dimension of the x along the x axis
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in
            
            // Here the dimension of the box along the x axis is updated.
            slider_xyz = viewModel.set_scale(new_scale: slider_xyz)
        }
        Text("\(slider_xyz[0], specifier: "X: %.2f m")")
        
        Slider(
            value: $slider_xyz[1],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in
            slider_xyz = viewModel.set_scale(new_scale: slider_xyz)
        }
        Text("\(slider_xyz[1], specifier: "Y: %.2f m")")
        
        
        Slider(
            value: $slider_xyz[2],
            in: 0...5,
            step: 0.1
        ).onChange(of: slider_xyz) {new_scale in 
            slider_xyz = viewModel.set_scale(new_scale: slider_xyz)
        }
        Text("\(slider_xyz[2], specifier: "Z: %.2f m")")
    }
}

/**
    Creates a button that repeats an action if the user holds it down.
 */
struct PressAndHoldButton: View {
    @State private var timer: Timer?
    @State var isLongPressing = false
    var action: (() -> Void) // Function to perform when button is held
    var title: String
    init(action: @escaping () -> Void, title: String) {
        self.action = action
        self.title = title
    }
    
    var body: some View {
        VStack {
            Button(action: {
                if self.isLongPressing {
                    // This tap was caused by the end of a long press gesture, so stop our fast forwarding
                    self.isLongPressing.toggle()
                    self.timer?.invalidate()
                } else {
                    // Perform the action once
                    self.action()
                }
            }) {
                Text(self.title)
                    .padding(.horizontal,20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                self.isLongPressing = true
                // To start the timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                    // Perform the action continuously
                    self.action()
                })
            })
        }
    }
}

@available(iOS 17.0, *)
struct ExtendControlsView : View {
    @ObservedObject var viewModel: ARViewModel
    @Binding var slider_xyz: [Float]
    @Binding var box_center: [Float]

    /**
     A view for expanding and shrinking each face of the bounding box individually. This view differs from the `ScaleControlView` in that `ScaleControlView` will extend both ends of an edge to fit the new length, but
     `ExtendControlsView` will only extend/shrink one end of an edge to fit the new length.
     
     - Parameter center: A binding to an array of floats representing the center of the box.
     - Parameter xyz: A binding to an array of floats representing the scale of the box.
     - Parameter vm: The ARViewModel that holds the `BoundingBox` object and methods for updating it.
     */
    init(center: Binding<[Float]>, xyz: Binding<[Float]>, vm: ARViewModel){
        viewModel = vm
        _slider_xyz = xyz
        _box_center = center
    }
    var body: some View {
        HStack{
            VStack{
                Spacer()
                // Calls the `viewModel.extend_sides` function to expand the box in an axis aligned manner
                Text("Extend Side")
                PressAndHoldButton(action:{
                    (box_center, slider_xyz) = viewModel.extend_sides(offset: [0,0,-0.1])
                }, title:"front")
                HStack{
                    PressAndHoldButton(action:{
                        (box_center, slider_xyz) = viewModel.extend_sides(offset: [-0.1,0,0])
                    }, title:"left")
                    PressAndHoldButton(action:{
                        (box_center, slider_xyz) = viewModel.extend_sides(offset: [0.1,0,0])
                    }, title:"right")
                }
                PressAndHoldButton(action:{
                    (box_center, slider_xyz) = viewModel.extend_sides(offset: [0,0,0.1])
                }, title:"back")
            }
            Spacer()
            VStack{
                Spacer()
                Text("Shrink Side")
                PressAndHoldButton(action:{
                    (box_center, slider_xyz) = viewModel.shrink_sides(offset: [0,0,0.1])
                }, title:"front")
                HStack{
                    PressAndHoldButton(action:{
                        (box_center, slider_xyz) = viewModel.shrink_sides(offset: [-0.1,0,0])
                    }, title:"right")
                    PressAndHoldButton(action:{
                        (box_center, slider_xyz) = viewModel.shrink_sides(offset: [0.1,0,0])
                    }, title:"left")
                }
                PressAndHoldButton(action:{
                    (box_center, slider_xyz) = viewModel.shrink_sides(offset: [0,0,-0.1])
                }, title:"back")
            }
        }
    }
}

// Unused
@available(iOS 17.0, *)
struct PointCloudControlsView: View {
    @ObservedObject var viewModel: ARViewModel
    init(vm: ARViewModel){
        viewModel = vm
    }
    var body: some View {
        VStack{
            Spacer()
            
            if let frame = viewModel.session?.currentFrame {
//                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.raycast_center(frame))}, title:"Use PCL")
//                PressAndHoldButton(action:{ActionManager.shared.actionStream.send(.drop(frame))}, title:"drop to floor")

            }
        }
    }
}


//#if DEBUG
//struct BoundingBox_Previews : PreviewProvider {
//    static var previews: some View {
//        BoundingBoxView(viewModel: ARViewModel(datasetWriter: DatasetWriter(), ddsWriter: DDSWriter()))
//            .previewInterfaceOrientation(.portrait)
//    }
//}
//#endif
