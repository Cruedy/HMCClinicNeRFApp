//
//  ARViewModel.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 13/7/2022.
//

import Foundation
import Zip
import Combine
import ARKit
import RealityKit
import os.log
enum AppError : Error {
    case projectAlreadyExists
    case manifestInitializationFailed
}

class ARViewModel : NSObject, ARSessionDelegate, ObservableObject {
    @Published var appState = AppState()
    var session: ARSession? = nil
    var arView: ARView? = nil
//    let frameSubject = PassthroughSubject<ARFrame, Never>()
    var cancellables = Set<AnyCancellable>()
    let datasetWriter: DatasetWriter
    let ddsWriter: DDSWriter
    var bBoxPosition: [[Float]]
    
    init(datasetWriter: DatasetWriter, ddsWriter: DDSWriter) {
        self.datasetWriter = datasetWriter
        self.ddsWriter = ddsWriter
        self.bBoxPosition = [[-0.5, 0.5, -2], [0.5, 0.5, -2], [0.5, -0.5, -2], [-0.5, -0.5, -2],
                             [-0.5, 0.5, -3], [0.5, 0.5, -3], [0.5, -0.5, -3], [-0.5, -0.5, -3]]
        super.init()
        self.subscribeToActionStream()
        self.setupObservers()
        self.ddsWriter.setupDDS()
    }
    
    func setupObservers() {
        datasetWriter.$writerState.sink {x in self.appState.writerState = x} .store(in: &cancellables)
        datasetWriter.$currentFrameCounter.sink { x in self.appState.numFrames = x }.store(in: &cancellables)
        ddsWriter.$peers.sink {x in self.appState.ddsPeers = UInt32(x)}.store(in: &cancellables)
        
        $appState
            .map(\.appMode)
            .prepend(appState.appMode)
            .removeDuplicates()
            .sink { x in
                switch x {
                case .Offline:
                    os_log("This is a default log message")

//                    self.appState.stream = false
                    print("Changed to offline")
//                case .Online:
//                    os_log("This is a default log message")
//
//                    print("Changed to online")
                }
            }
            .store(in: &cancellables)
        
//        frameSubject.throttle(for: 0.5, scheduler: RunLoop.main, latest: true).sink {
//            f in
//            if self.appState.stream && self.appState.appMode == .Online {
//                self.ddsWriter.writeFrameToTopic(frame: f)
//            }
//        }.store(in: &cancellables)
    }
    
    func subscribeToActionStream() {
            ActionManager.shared
                .actionStream
                .sink { [weak self] action in
                    
                    switch action {
                        
                    case .heartbeat(let data):
                        print("got something")
                        print(data)
                        
                    }
                }
                .store(in: &cancellables)
        }
        
    
    func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            // Activate sceneDepth
            configuration.frameSemantics = .sceneDepth
        }
        return configuration
    }
    
    func resetWorldOrigin() {
        session?.pause()
        let config = createARConfiguration()
        session?.run(config, options: [.resetTracking])
    }
    
    func session(
        _ session: ARSession,
        didUpdate frame: ARFrame
    ) {
//        frameSubject.send(frame)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.appState.trackingState = trackingStateToString(camera.trackingState)
    }
}

enum Actions {
    case heartbeat(String)
}



class ActionManager {
    static let shared = ActionManager()
    
    private init() { }
    
    var actionStream = PassthroughSubject<Actions, Never>()
}
