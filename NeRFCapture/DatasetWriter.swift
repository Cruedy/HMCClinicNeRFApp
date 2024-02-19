//
//  DatasetWriter.swift
//  NeRFCapture
//
//  Created by Jad Abou-Chakra on 11/1/2023.
//

import Foundation
import ARKit
import Zip
import UIKit
import AVFoundation


extension UIImage {
    func resizeImageTo(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class DatasetWriter {
    
    enum SessionState {
        case SessionNotStarted
        case SessionStarted
        case SessionPaused
    }
    
    var manifest = Manifest()
    var boundingBoxManifest: BoundingBoxManifest?
    var projectName = ""
    var projectDir = getDocumentsDirectory()
    var useDepthIfAvailable = true
    
    @Published var currentFrameCounter = 0
    @Published var writerState = SessionState.SessionNotStarted
    
    @IBOutlet var takePictureButton: UIBarButtonItem?
    @IBOutlet var startStopButton: UIBarButtonItem?
    @IBOutlet var delayedPhotoButton: UIBarButtonItem?
    @IBOutlet var doneButton: UIBarButtonItem?
    
    
    let imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        return picker
    }()

    
    func projectExists(_ projectDir: URL) -> Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: projectDir.absoluteString, isDirectory: &isDir)
    }
    
    func initializeProject() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMddHHmmss"
        projectName = dateFormatter.string(from: Date())
        projectDir = getDocumentsDirectory()
            .appendingPathComponent(projectName)
        if projectExists(projectDir) {
            throw AppError.projectAlreadyExists
        }
        do {
            try FileManager.default.createDirectory(at: projectDir.appendingPathComponent("images"), withIntermediateDirectories: true)
        }
        catch {
            print(error)
        }
        
        manifest = Manifest()
        
        // The first frame will set these properly
        manifest.w = 0
        manifest.h = 0
        
        // These don't matter since every frame will redefine them
        manifest.flX = 1.0
        manifest.flY =  1.0
        manifest.cx =  320
        manifest.cy =  240
        
        manifest.depthIntegerScale = 1.0
        writerState = .SessionStarted
    }
    
    func pauseSession() {
        writerState = .SessionPaused
    }
    
    func clean() {
        guard case .SessionStarted = writerState else { return; }

        writerState = .SessionNotStarted
        DispatchQueue.global().async {
            do {
                try FileManager.default.removeItem(at: self.projectDir)
            }
            catch {
                print("Could not cleanup project files")
            }
        }
    }
    
    func finalizeSession() {
        writerState = .SessionNotStarted
        let manifest_path = getDocumentsDirectory()
            .appendingPathComponent(projectName)
            .appendingPathComponent("transforms.json")

        if let documentDirectory = FileManager.default.documentDirectory {
            let urls = FileManager.default.getContentsOfDirectory(documentDirectory).filter { $0.isImage }
        }
        
        writeManifestToPath(path: manifest_path)
        
        let boundingboxmanifest_path = getDocumentsDirectory()
            .appendingPathComponent(projectName)
            .appendingPathComponent("boundingbox.json")
        
        writeBoundingBoxManifestToPath(path: boundingboxmanifest_path)
        
    }
     
    func finalizeProject(zip: Bool = true) {
        writerState = .SessionNotStarted
        let manifest_path = getDocumentsDirectory()
            .appendingPathComponent(projectName)
            .appendingPathComponent("transforms.json")

        if let documentDirectory = FileManager.default.documentDirectory {
            print("document Directory")
            print(documentDirectory)
            let urls = FileManager.default.getContentsOfDirectory(documentDirectory).filter { $0.isImage }}
        
        writeManifestToPath(path: manifest_path)

        let boundingbox_manifest_path = getDocumentsDirectory()
            .appendingPathComponent(projectName)
            .appendingPathComponent("boundingbox.json")

        writeBoundingBoxManifestToPath(path: boundingbox_manifest_path)
        
        DispatchQueue.global().async {
            do {
                if zip {
                    let _ = try Zip.quickZipFiles([self.projectDir], fileName: self.projectName)
                }
                try FileManager.default.removeItem(at: self.projectDir)
            }
            catch {
                print("Could not zip")
            }
        }
    }
    
    func getCurrentFrameName() -> String {
        let frameName = String(currentFrameCounter)
        return frameName
    }
    
    func getFrameMetadata(_ frame: ARFrame, withDepth: Bool = false) -> Manifest.Frame {
        let frameName = getCurrentFrameName()
        let filePath = "images/\(frameName)"
        let depthPath = "images/\(frameName).depth.png"
        let manifest_frame = Manifest.Frame(
            filePath: filePath,
            depthPath: withDepth ? depthPath : nil,
            transformMatrix: arrayFromTransform(frame.camera.transform),
            timestamp: frame.timestamp,
            flX:  frame.camera.intrinsics[0, 0],
            flY:  frame.camera.intrinsics[1, 1],
            cx:  frame.camera.intrinsics[2, 0],
            cy:  frame.camera.intrinsics[2, 1],
            w: Int(frame.camera.imageResolution.width),
            h: Int(frame.camera.imageResolution.height)
        )
        return manifest_frame
    }
    
    func writeManifestToPath(path: URL) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .withoutEscapingSlashes
        if let encoded = try? encoder.encode(manifest) {
            do {
                try encoded.write(to: path)
            } catch {
                print(error)
            }
        }
    }
    
    func writeBoundingBoxManifestToPath(path: URL) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .withoutEscapingSlashes
        if let encoded = try? encoder.encode(boundingBoxManifest) {
            do {
                try encoded.write(to: path)
            } catch {
                print(error)
            }
        }
    }
    
    func writeFrameToDisk(frame: ARFrame, useDepthIfAvailable: Bool = true) {
        let frameName =  "\(getCurrentFrameName()).png"
        let depthFrameName =  "\(getCurrentFrameName()).depth.png"
        let baseDir = projectDir
            .appendingPathComponent("images")
        let fileName = baseDir
            .appendingPathComponent(frameName)
        let depthFileName = baseDir
            .appendingPathComponent(depthFrameName)
        let deviceOrientation = UIDevice.current.orientation
        var angle: CGFloat = 0.0
        
        switch deviceOrientation{
        case .portrait:
            angle = CGFloat.pi/2
            break
        case .portraitUpsideDown:
            angle = -CGFloat.pi/2
            break
        case .landscapeLeft:
            angle = 0
            break
        case .landscapeRight:
            angle = CGFloat.pi
            break
        default:
            break
        }
        
        let useDepth = frame.sceneDepth != nil && useDepthIfAvailable
        
        let frameMetadata = getFrameMetadata(frame, withDepth: useDepth)
        let rgbBuffer = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)
        let depthBuffer = useDepth ? pixelBufferToUIImage(pixelBuffer: frame.sceneDepth!.depthMap).resizeImageTo(size:  frame.camera.imageResolution) : nil
        
        DispatchQueue.global().async {
            do {
                if let rotatedRGBBuffer = self.rotateImage(rgbBuffer, angle: angle){
                    let rotatedRGBData = rotatedRGBBuffer.pngData()
                    try rotatedRGBData?.write(to: fileName)
                }
                if useDepth {
                    if let rotatedDepthBuffer = self.rotateImage(depthBuffer!, angle: angle){
                        let rotatedDepthData = rotatedDepthBuffer.pngData()
                        try rotatedDepthData?.write(to: depthFileName)
                    }
                }
            }
            catch {
                print(error)
            }
            DispatchQueue.main.async {
                self.manifest.frames.append(frameMetadata)
            }
        }
        currentFrameCounter += 1
    }
    
    fileprivate struct PhotoData {
        var thumbnailImage: UIImage
        var thumbnailSize: (width: Int, height: Int)
        var imageData: Data
        var imageSize: (width: Int, height: Int)
    }
    
    func rotateImage(_ image: UIImage, angle: CGFloat) -> UIImage? {
        // Calculate the new size of the image after rotation
            let rotatedViewBox = UIView(frame: CGRect(origin: .zero, size: image.size))
            let t = CGAffineTransform(rotationAngle: angle)
            rotatedViewBox.transform = t
            let rotatedSize = rotatedViewBox.frame.size

            // Begin a new image context
            UIGraphicsBeginImageContext(rotatedSize)
            guard let bitmap = UIGraphicsGetCurrentContext() else { return nil }

            // Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)

            // Rotate the image context
            bitmap.rotate(by: angle)

            // Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(image.cgImage!, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))

            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage
    }
}
