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
    }
    
    var manifest = Manifest()
    var projectName = ""
    var projectDir = getDocumentsDirectory()
    var useDepthIfAvailable = true
    
    @Published var currentFrameCounter = 0
    @Published var writerState = SessionState.SessionNotStarted
    
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
        
//        dataModel.initializeGallery()
        
        writeManifestToPath(path: manifest_path)
//        DispatchQueue.global().async {
//            do {
//                if zip {
//                    let _ = try Zip.quickZipFiles([self.projectDir], fileName: self.projectName)
//                }
//                try FileManager.default.removeItem(at: self.projectDir)
//            }
//            catch {
//                print("Could not zip")
//            }
//        }
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
            angle = 0
            break
        case .portraitUpsideDown:
            angle = .pi
            break
        case .landscapeLeft:
            angle = .pi/2.0
            break
        case .landscapeRight:
            angle = -.pi/2.0
            break
        default:
            break
        }
        
        print("angle")
        print(angle)
        
        if angle == 0.0 {
            print("here")
            manifest.h = Int(frame.camera.imageResolution.width)
            manifest.w = Int(frame.camera.imageResolution.height)
            manifest.flX =  frame.camera.intrinsics[1, 1]
            manifest.flY =  frame.camera.intrinsics[0, 0]
            manifest.cx =  frame.camera.intrinsics[2, 1]
            manifest.cy =  frame.camera.intrinsics[2, 0]
        }
        
        if manifest.w == 0 {
//            print("here also")
//            manifest.w = Int(frame.camera.imageResolution.height)
//            manifest.h = Int(frame.camera.imageResolution.width)
            manifest.w = Int(frame.camera.imageResolution.width)
            manifest.h = Int(frame.camera.imageResolution.height)
            manifest.flX =  frame.camera.intrinsics[0, 0]
            manifest.flY =  frame.camera.intrinsics[1, 1]
            manifest.cx =  frame.camera.intrinsics[2, 0]
            manifest.cy =  frame.camera.intrinsics[2, 1]
        }
        
        print(manifest.cx)
        
        let useDepth = frame.sceneDepth != nil && useDepthIfAvailable
        
        let frameMetadata = getFrameMetadata(frame, withDepth: useDepth)
        let rgbBuffer = pixelBufferToUIImage(pixelBuffer: frame.capturedImage)
        let depthBuffer = useDepth ? pixelBufferToUIImage(pixelBuffer: frame.sceneDepth!.depthMap).resizeImageTo(size:  frame.camera.imageResolution) : nil
        
        let rotatedRGBBuffer = rotateImage(rgbBuffer, withAngle: angle)
        let rotatedDepthBuffer = useDepth ? rotateImage(depthBuffer!, withAngle: angle) : nil
        
        
        DispatchQueue.global().async {
            do {
                let rotatedRGBData = rotatedRGBBuffer?.pngData()
                try rotatedRGBData?.write(to: fileName)
                if useDepth {
                    let rotatedDepthData = rotatedRGBBuffer?.pngData()
                    try rotatedDepthData?.write(to: depthFileName)
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
    
    func rotateImage(_ image: UIImage, withAngle angle: CGFloat) -> UIImage? {
        // Convert angle in degrees to radians
        let radians = angle / 180.0 * CGFloat.pi
        // Define the new size
        var newSize = CGRect(origin: CGPoint.zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        // Ensure newSize is positive
        newSize.width = abs(newSize.width)
        newSize.height = abs(newSize.height)
        // Create a new graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate the image context
        context.rotate(by: radians)
        // Now, draw the rotated/scaled image into the context
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }
    
//    func rotateImage(_ image: UIImage, by angle: CGFloat, basedOn deviceOrientation: UIDeviceOrientation) -> UIImage? {
//        guard let cgImage = image.cgImage else {
//            return nil
//        }
//
//        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
//        var transform = CGAffineTransform.identity
//
//        // Apply rotation based on the specified angle
//        transform = transform.rotated(by: angle)
//
//        // Adjust rotation based on device orientation
//        switch deviceOrientation {
//        case .landscapeLeft:
//            transform = transform.rotated(by: .pi / 2.0)
//        case .landscapeRight:
//            transform = transform.rotated(by: -.pi / 2.0)
//        case .portraitUpsideDown:
//            transform = transform.rotated(by: .pi)
//        default:
//            break
//        }
//
//        if let context = CGContext(data: nil, width: Int(imageSize.width), height: Int(imageSize.height),
//                                   bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
//                                   space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue) {
//
//            context.concatenate(transform)
//            context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
//
//            if let rotatedImage = context.makeImage() {
//                return UIImage(cgImage: rotatedImage)
//            }
//        }
//
//        return nil
//    }
}
