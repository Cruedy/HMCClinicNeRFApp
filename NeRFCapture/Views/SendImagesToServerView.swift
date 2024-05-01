//
//  SendImagesToServerView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import Zip
import Foundation

@available(iOS 17.0, *)
struct SendImagesToServerView: View {
    @State private var showingInstructions = false
    @State private var serverResponse: String = "Awaiting response..."
    @State private var serverStatus: ServerStatus?
    @State private var serverError: String = ""
    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @Binding var path: NavigationPath // unused
    @Binding var currentView: NavigationDestination

    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // recurring server action every 1s.

    /**
        Initializes a new instance of the `SendImagesToServerView` view with the specified view model and bindings.

        - Parameter viewModel: An instance of `ARViewModel` that will manage the augmented reality data and interactions.
        - Parameter path: A binding to a `NavigationPath` object which tracks the navigation state within the app. This parameter is currently unused in this view.
        - Parameter currentView: A binding to a `NavigationDestination` that tracks the current view in the navigation hierarchy.

        Note: The `path` parameter is marked as unused and might be reserved for future routing enhancements or navigation controls.
    */
    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>, currentView: Binding<NavigationDestination>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
        _currentView = currentView
    }

    var body: some View {
        VStack {  // Main UI portion
            Text(testForStatus(status: serverStatus))
            .padding()
            
            Spacer()
            
            Button(action: {
                print("send zip to server")
                let urlString = "http://osiris.cs.hmc.edu:15002/upload_device_data"
                let directoryPath = viewModel.datasetWriter.projectDir
                let zipPath = convertDirectoryPathToZipPath(directoryPath: directoryPath.absoluteString)
                print(zipPath)
                uploadZipFile(urlString: urlString, zipFilePath: URL(string: zipPath)!, splatName: viewModel.datasetWriter.projectName)
            }) {
                Text("Begin Rendering")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            Spacer()

            // Very useful button for debugging. Gets a video for the splatt corresponding to the projName, as long as the video exists on Server.
//            Button(action: {
//                print("get video")
//                let urlString = "http://osiris.cs.hmc.edu:15002/download_video/\(viewModel.datasetWriter.projName)"
//                downloadVideo(urlString: urlString, splatName: viewModel.datasetWriter.projName)
//            }) {
//                Text("get video")
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 5)
//            }
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)
//            
//            Spacer()
            

            Button("View Results") {
                currentView = .videoView
            }
                .padding(.horizontal,20)
                .padding(.vertical, 5)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            
            HelpButton {
                showingInstructions = true
            }
            .sheet(isPresented: $showingInstructions) {
                VStack {
                    InstructionsView()
                }
            }
        }
        .onAppear {
                    // Reconnect the timer if needed when the view appears or reappears
                    self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        }
        .onReceive(timer) { _ in
            
            // polls the server for status
            let urlString = "http://osiris.cs.hmc.edu:15002/status"
            makeGetRequest(urlString: urlString) { data, response, error in
                pollServerStatus(data: data, response: response, error: error)
            }
            
            // when the rendering is complete on the server, request the video and webviewer detailed view link. This will reset the status to `waiting_for_data` on the server.
            if serverStatus == ServerStatus.rendering_ended {
                let videoUrlString = "http://osiris.cs.hmc.edu:15002/download_video/\(viewModel.datasetWriter.projName)"
                downloadVideo(urlString: videoUrlString, splatName: viewModel.datasetWriter.projName)
                let webViewerUrlString = "http://osiris.cs.hmc.edu:15002/get_webviewer_link/\(viewModel.datasetWriter.projName)"
                getWebViewerUrl(urlString: webViewerUrlString, splatName: viewModel.datasetWriter.projName) { url, error in
                    if let error = error {
                        print("Error fetching URL: \(error.localizedDescription)")
                    } else if let url = url {
                        print("Web Viewer URL: \(url)")
                        
                        // saving the url to the WebViewer link of this splat in the datasetWriter isn't best practice,
                        // but it does save one more variable to be passed from this view to the VideoView constructor,
                        // which simplifies the ContentView case statement.
                        viewModel.datasetWriter.webViewerUrl = url
                    }
                }
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears to stop the polling
            self.timer.upstream.connect().cancel()
        }
        .preferredColorScheme(.dark)
        
        // --- Navigation Bar ---
        .navigationBarTitle("Send to Server")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown, use the currentView to change views programmatically.
    }
    
    
    /**
        Creates a more user friendly message reflecting the server status
     
        - Parameter status: a enum that has a one to one match on the server.
     
        - Returns either a string or an error message.
     */
    func testForStatus(status: ServerStatus?) -> String {
        if let status = status {
            switch status {
            case .waiting_for_data:
                return "Server is ready for upload"
            case .data_upload_started:
                return "Server is extracting uploaded data"
            case .data_upload_ended:
                return "Server finished extracting uploaded data"
            case .preprocessing_started:
                return "Server is preprocessing data"
            case .preprocessing_ended:
                return "Server is done preprocessing data"
            case .training_started:
                return "Server started training"
            case .training_ended:
                return "Server finished training"
            case .rendering_started:
                return "Server is rendering video"
            case .rendering_ended:
                return "Server finished rendering video"
            case .data_upload_error:
                return "Error: data upload failed"
            case .preprocessing_error:
                return "Error: preprocessing failed"
            case .training_error:
                return "Error: training failed"
            case .rendering_error:
                return "Error: rendering failed"
            }
        }
        return serverError
    }
    
    /**
     Requests the server status and saves it in `serverStatus`. Saves certain errors in `serverError`.
     - Parameter data: Data returned by the server, if any.
     - Parameter response: The URL response associated with the request.
     - Parameter error: Any error encountrered during the request.
     
     Example Usage:
     ```
     let urlString = "http://osiris.cs.hmc.edu:15002/status"
     makeGetRequest(urlString: urlString) { data, response, error in
         pollServerStatus(data: data, response: response, error: error)
     }
     ```
     */
    func pollServerStatus(data: Data?, response: URLResponse?, error: Error?) {
        // Check for errors
        if let error = error {
            print("Error: \(error)")
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "Error: \(error.localizedDescription)"
            }
            return
        }

        // Check for valid data
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let data = data else {
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "No data or invalid response"
            }
            return
        }

        // Process the data
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let status = json["status"] as? String {
                print(status)
                DispatchQueue.main.async {
                    if status == "waiting_for_data"{
                        self.serverStatus = ServerStatus.waiting_for_data
                    } else if status == "data_upload_started" {
                        self.serverStatus = ServerStatus.data_upload_started
                    } else if status == "data_upload_ended" {
                        self.serverStatus = ServerStatus.data_upload_ended
                    } else if status == "preprocessing_started" {
                        self.serverStatus = ServerStatus.preprocessing_started
                    } else if status == "preprocessing_ended" {
                        self.serverStatus = ServerStatus.preprocessing_ended
                    } else if status == "training_started" {
                        self.serverStatus = ServerStatus.training_started
                    } else if status == "training_ended" {
                        self.serverStatus = ServerStatus.training_ended
                    } else if status == "rendering_started" {
                        self.serverStatus = ServerStatus.rendering_started
                    } else if status == "rendering_ended" {
                        self.serverStatus = ServerStatus.rendering_ended
                    } else if status == "data_upload_error" {
                        self.serverStatus = ServerStatus.data_upload_error
                    } else if status == "preprocessing_error" {
                        self.serverStatus = ServerStatus.preprocessing_error
                    } else if status == "training_error" {
                        self.serverStatus = ServerStatus.training_error
                    } else if status == "rendering_error" {
                        self.serverStatus = ServerStatus.rendering_error
                    }
                    else{
                        self.serverStatus = nil
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.serverStatus = nil
                    self.serverError = "Received unknown response"
                }
            }
        } catch let error {
            print("JSON error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "JSON error: \(error.localizedDescription)"
            }
        }
    }
    
    /**
        Properly append `.zip` at the end of a directory.

        - Parameter directoryPath:   Path of the directory that should be a zip file.

        - Returns: A new string ending in `.zip`
    */
    func convertDirectoryPathToZipPath(directoryPath: String) -> String {
        // Check if the directory path ends with a slash and remove it if present
        var adjustedPath = directoryPath
        if adjustedPath.hasSuffix("/") {
            adjustedPath.removeLast()
        }
        
        // Append '.zip' to the adjusted path
        let zipPath = "\(adjustedPath).zip"
        
        return zipPath
    }

    
    /**
        Initiates an asynchronous HTTP GET request to the specified URL and returns the results via a completion handler.

        - Parameter urlString: The URL string where the GET request will be sent. This string must be a valid URL format.
        - Parameter completion: A closure that is executed once the request completes. This closure has three optional parameters:
          - `Data?`: Data returned by the server, if any.
          - `URLResponse?`: The URL response associated with the request.
          - `Error?`: An error encountered during the request.

        - Note: If the `urlString` is not a valid URL, the function prints "Invalid URL" to the console, sets `serverResponse` to "Invalid URL", and the completion handler is not called with server data.

        This function does not handle the parsing of the received data or manage UI updates directly; such responsibilities should be handled within the completion handler, considering appropriate thread management.
    */    
    func makeGetRequest(urlString: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.serverResponse = "Invalid URL"
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
        }

        task.resume()
    }

    /**
        Uploads the zip file containing images, depth images, bounding box json, and transforms json.

        - Parameter urlString: Endpoint to upload the zip file (currently "http://osiris.cs.hmc.edu:15002/upload_device_data").
        - Parameter zipFilePath: Path to data to be uploaded.
        - Parameter splatName: Name of the uploaded data (should be unique on the server).

        - Throws: An error if the ZIP file could not be prepared for upload due to issues like non-existence of the file at the specified path or inability to read the file data.
    */
    func uploadZipFile(urlString: String, zipFilePath: URL, splatName: String) {
        let fileManager = FileManager.default
        do {
            guard fileManager.fileExists(atPath: zipFilePath.path) else {
                print("ZIP file does not exist at specified path.")
                return
            }
            
            let filename = zipFilePath.lastPathComponent
            let mimeType = "application/zip"
            let fileData = try Data(contentsOf: zipFilePath)
            
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            // Add the ZIP file data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            
            // add the splatName
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"splatName\"\r\n\r\n".data(using: .utf8)!)
            data.append(splatName.data(using: .utf8)!)
            
            // End of the multipart/form-data
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("ZIP file uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error preparing ZIP file for upload: \(error)")
        }
    }
    
    /**
        Download a preview video of the resulting splat from the server and moves it to a file named with the splat's name in the files folder of the app.

        - Parameter urlString: Endpoint to download the preview video (currently "http://osiris.cs.hmc.edu:15002/download_video/${splatName}").
        - Parameter splatName: Name of the uploaded data (should be unique on the server).

        - Throws: An error if the video does not download or if unable to move to the app's folder
    */
    func downloadVideo(urlString: String, splatName: String) {
        
        guard let downloadURL = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, urlResponse, error in
            guard let localURL = localURL else {
                print("Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if FileManager.default.fileExists(atPath: localURL.path) {
                print("Temporary file exists: \(localURL.path)")
            } else {
                print("Temporary file does not exist.")
                return
            }
            
            // Move the downloaded video to the app's folder and rename the name of the file to be the splatName.
            do {
                let fileManager = FileManager.default
                let documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let savedURL = documentsPath.appendingPathComponent("\(splatName).mp4")
                
                // Check if file exists, remove it
                if fileManager.fileExists(atPath: savedURL.path) {
                    try fileManager.removeItem(at: savedURL)
                }
                
                // Move the downloaded file to the new location
                try fileManager.moveItem(at: localURL, to: savedURL)
                print("File moved to documents folder: \(savedURL)")
            } catch {
                print("File error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }

    /**
        Download the link of the resulting splat to the WebViewer detailed view from the server and allows additional action through the completion closure

        - Parameter urlString: Endpoint to download the preview video (currently "http://osiris.cs.hmc.edu:15002/download_video/${splatName}").
        - Parameter splatName: Name of the uploaded data (should be unique on the server).
        - Parameter completion: A closure that is called after the attempt to download the video. It takes two parameters:
           - `String?`: The URL as a string if the download is successful and the link is valid.
           - `Error?`: An error object that describes what went wrong during the download process.

        - Throws: An error if the WebViewer link does not download .
    */
    func getWebViewerUrl(urlString: String, splatName: String, completion: @escaping (String?, Error?) -> Void) {
        let getWebViewerUrlString = urlString
        
        guard let url = URL(string: getWebViewerUrlString) else {
            print("Invalid URL")
            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error occurred: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("No data received from the server")
                completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let webviewerLink = json["webviewerLink"] as? String {
                    print("Webviewer LINK: ", webviewerLink)
                    completion(webviewerLink, nil)
                } else {
                    print("Failed to parse JSON or 'webviewerLink' missing")
                    completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON Parsing Error"]))
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
        
        task.resume()
    }
   
    
    
// unused functions
    // Sends a post request to change the splatname on the server. We don't use this anymore because the splatname is sent with the zip file now.
    func uploadSplatName(urlString: String, splatName: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["splatName": splatName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    // Update your UI here if necessary
                    print("Splat name uploaded successfully.")
                }
            } else {
                print("Upload failed with response: \(String(describing: response))")
            }
        }
        
        task.resume()
    }
    
   func processData(data: Data?, response: URLResponse?, error: Error?) {
       // Check for errors
       if let error = error {
           print("Error: \(error)")
           DispatchQueue.main.async {
               self.serverResponse = "Error: \(error.localizedDescription)"
           }
           return
       }
       // Check for valid data
       guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
             let data = data else {
           DispatchQueue.main.async {
               self.serverResponse = "No data or invalid response"
           }
           return
       }
       // Process the data
       do {
           if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let message = json["message"] as? String {
               DispatchQueue.main.async {
                   self.serverResponse = message
               }
           } else {
               DispatchQueue.main.async {
                   self.serverResponse = "Received unknown response"
               }
           }
       } catch let error {
           print("JSON error: \(error.localizedDescription)")
           DispatchQueue.main.async {
               self.serverResponse = "JSON error: \(error.localizedDescription)"
           }
       }
   }
    
    // POST request to upload a folder of images. This is now done as part of the zip file upload.
    func uploadPhotos(urlString: String, directoryPath: URL) {
        // Assuming `directoryPath` is the path to the directory containing photos
        let fileManager = FileManager.default
        do {
            // URL(fileURLWithPath: directoryPath)
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryPath,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            for fileURL in fileURLs {
                print("fileURL")
                print(fileURL)
                let filename = fileURL.lastPathComponent
                let mimeType = "image/png" // Adjust based on your actual file type
                let fileData = try Data(contentsOf: fileURL)
                
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(fileData)
            }
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Files uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error reading directory: \(error)")
        }
    }
    
    
    func uploadJSONFile(urlString: String, fileURL: URL) {
        // Ensure the URL is valid
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Append the file data to the request body
        let filename = fileURL.lastPathComponent
        let mimeType = "application/json" // MIME type for JSON files
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        } catch {
            print("Error reading file: \(error)")
            return
        }
        
        request.httpBody = data
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("File uploaded successfully.")
            } else {
                print("Upload failed with response: \(String(describing: response))")
            }
        }
        task.resume()
    }
    
    func uploadBoundingBox(urlString: String, directoryPath: URL) {
        // Assuming `directoryPath` is the path to the directory containing photos
        let fileManager = FileManager.default
        do {
            // URL(fileURLWithPath: directoryPath)
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryPath,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            for fileURL in fileURLs {
                print("fileURL")
                print(fileURL)
                let filename = fileURL.lastPathComponent
                let mimeType = "image/png" // Adjust based on your actual file type
                let fileData = try Data(contentsOf: fileURL)
                
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(fileData)
            }
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Files uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error reading directory: \(error)")
        }
    }
    
    
    /**
        Sends a request to the server to start the full rendering pipeline. This includes preprocessing, 3D Gaussian Splatting, and Rendering. This step comes after the data upload.

        - Parameter urlString: Endpoint to download the preview video (currently "http://osiris.cs.hmc.edu:15002/full_pipeline").

        - Throws: An error if the pipeline fails on the server
     
        - Warning: This function is no longer needed but likely working. The server automatically starts the full pipline upon recieving data, so this function call is both unneccessary and should be avoided.
    */
    func startFullPipeline(urlString: String) {

//        // You can use the below to check the server has already recieved data and is ready for update
//        let statusUrlString = "http://osiris.cs.hmc.edu:15002/status"
//        makeGetRequest(urlString: statusUrlString) { data, response, error in
//            pollServerStatus(data: data, response: response, error: error)
//        }
//        if (serverStatus != ServerStatus.data_upload_ended)
//        {
//            print("Server isn't ready")
//            return
//        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // Send the post request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    print("pipeline started successfully.")
                }
            } else {
                print("pipeline failed with response: \(String(describing: response))")
            }
        }
        task.resume()
    }
}



enum ServerStatus {
    case waiting_for_data
    case data_upload_started
    case data_upload_ended
    case preprocessing_started
    case preprocessing_ended
    case training_started
    case training_ended
    case rendering_started
    case rendering_ended
    case data_upload_error
    case preprocessing_error
    case training_error
    case rendering_error

}



